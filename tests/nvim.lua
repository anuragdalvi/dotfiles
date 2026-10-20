-- Run: nvim --headless -i NONE '+luafile tests/nvim.lua' '+qa!'
-- Uses temporary fixtures and intercepted actions: never stages/resets real Git files.
local function eq(actual, expected)
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, 'p')
fixture = vim.uv.fs_realpath(fixture)
local saved = {
  system = vim.system, get_clients = vim.lsp.get_clients,
  get_client_by_id = vim.lsp.get_client_by_id, notify = vim.notify,
  completion_enable = vim.lsp.completion.enable,
}
local function run()
  for _, name in ipairs({ 'gopls', 'basedpyright', 'terraformls' }) do vim.lsp.enable(name, false) end
  assert(not package.loaded.octo and not package.loaded.neogit and not package.loaded.diffview)
  eq(vim.fn.maparg(' h', 'n'), '')
  eq(vim.fn.maparg('gr', 'n'), '')
  eq(vim.fn.maparg('gt', 'n'), '')
  assert(vim.fn.maparg(' ?', 'n', false, true).callback)
  eq(vim.g.mapleader, ' ')
  eq(vim.g.maplocalleader, ' ')
  eq(vim.o.timeoutlen, 250)
  assert(vim.o.undofile and vim.o.splitright and vim.o.splitbelow)
  assert(vim.o.ignorecase and vim.o.smartcase)
  for _, keys in ipairs({ ' hs', ' hr', ' hp', ' hb', ' -', ' |', ' w', ' c', '<C-h>', '<C-j>', '<C-k>', '<C-l>' }) do
    local mapping = vim.fn.maparg(keys, 'n', false, true)
    assert(mapping.desc, 'Missing ergonomic mapping: ' .. keys)
  end
  assert(vim.lsp.config.terraformls, 'Terraform language support is missing')

  local gs = require('gitsigns')
  for _, action in ipairs({ { 'hs', 'stage_hunk' }, { 'hr', 'reset_hunk' } }) do
    local original, captured = gs[action[2]], nil
    gs[action[2]] = function(range) captured = range end
    for _, selection in ipairs({ 'ggV2j', '3GV2k' }) do
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three', 'four' })
      vim.cmd.normal({ selection, bang = true })
      vim.fn.maparg(' ' .. action[1], 'x', false, true).callback()
      eq(captured, { 1, 3 })
      vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
    end
    gs[action[2]] = original
  end

  local function file(relative, lines)
    local name = fixture .. '/' .. relative
    vim.fn.mkdir(vim.fs.dirname(name), 'p')
    vim.fn.writefile(lines or {}, name)
    return name
  end
  local function buffer(name)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, name)
    return buf
  end
  local root_a, root_b = fixture .. '/a', fixture .. '/b'
  local buf_a = buffer(file('a/main.go'))
  local buf_b = buffer(file('b/main.go'))
  file('a/go.mod', { 'module example.com/a', 'go 1.24' })
  file('b/go.mod', { 'module example.com/b', 'go 1.24' })
  local clients, requests, notices = {}, {}, {}
  vim.notify = function(message) notices[#notices + 1] = message end
  vim.lsp.get_clients = function(filter)
    return vim.tbl_filter(function(client)
      return (not filter.name or client.name == filter.name)
        and (not filter.bufnr or client.attached_buffers[filter.bufnr])
        and (not filter.method or client:supports_method(filter.method))
    end, clients)
  end
  vim.system = function(command, opts, callback)
    eq(vim.list_slice(command, 1, 3), { 'go', 'env', '-json' })
    requests[#requests + 1] = { cwd = opts.cwd, callback = callback }
  end
  local root = vim.lsp.config.gopls.root_dir
  local resolved_a, resolved_a2, resolved_b
  root(buf_a, function(dir) resolved_a = dir end)
  root(buf_a, function(dir) resolved_a2 = dir end)
  root(buf_b, function(dir) resolved_b = dir end)
  eq(#requests, 2) -- concurrent buffers share a discovery request per root
  eq(requests[1].cwd, root_a)
  eq(requests[2].cwd, root_b)
  local env = { GOMODCACHE = fixture .. '/pkg/mod', GOROOT = fixture .. '/sdk' }
  for _, request in ipairs(requests) do request.callback({ code = 0, stdout = vim.json.encode(env) }) end
  assert(vim.wait(1000, function() return resolved_a and resolved_a2 and resolved_b end))
  eq({ resolved_a, resolved_a2, resolved_b }, { root_a, root_a, root_b })

  local function client(id, dir, buf)
    return { id = id, name = 'gopls', config = { root_dir = dir }, attached_buffers = { [buf] = true } }
  end
  clients = { client(11, root_a, buf_a), client(12, root_b, buf_b) }
  local dependency = buffer(file('sdk/src/fmt/print.go'))
  local chosen
  root(dependency, function(dir) chosen = dir end)
  eq(chosen, nil) -- ambiguous direct opens do not attach arbitrarily
  eq(#requests, 2) -- never ask Go to index its SDK as another project
  vim.api.nvim_exec_autocmds('BufLeave', { buffer = buf_a })
  root(dependency, function(dir) chosen = dir end)
  eq(chosen, root_a)
  clients = { clients[2] }
  root(dependency, function(dir) chosen = dir end)
  eq(chosen, root_b) -- stopped origin falls back to the sole live candidate
  clients = {}
  root(buf_a, function() end)
  eq(#requests, 3) -- restarting a project refreshes its Go environment
  requests[3].callback({ code = 0, stdout = vim.json.encode(env) })
  vim.wait(50, function() return false end)

  local python = vim.lsp.config.basedpyright
  eq(python.root_markers[1][1], 'pyrightconfig.json')
  file('a/.venv/bin/python', { '#!/bin/sh', 'exit 0' })
  vim.fn.setfperm(root_a .. '/.venv/bin/python', 'rwxr-xr-x')
  local config = { root_dir = root_a, settings = vim.deepcopy(python.settings) }
  local client_settings = config.settings
  python.before_init({}, config)
  eq(client_settings.python.pythonPath, root_a .. '/.venv/bin/python')
  eq(config.settings.python.pythonPath, root_a .. '/.venv/bin/python')
  config.settings.python.pythonPath = '/explicit/python'
  python.before_init({}, config)
  eq(config.settings.python.pythonPath, '/explicit/python')
  local other = { root_dir = root_b }
  python.before_init({}, other)
  eq(other.settings.python.pythonPath, nil)
  file('a/pyrightconfig.json')
  file('a/nested/pyproject.toml')
  local nested = buffer(file('a/nested/main.py'))
  eq(vim.fs.root(nested, python.root_markers), root_a .. '/nested')

  vim.fn.mkdir(root_a .. '/.git', 'p')
  vim.fn.mkdir(root_a .. '/infra/.terraform', 'p')
  local tf = buffer(file('a/infra/main.tf'))
  vim.lsp.config.terraformls.root_dir(tf, function(dir) chosen = dir end)
  eq(chosen, root_a)
  local standalone = buffer(file('standalone/main.tf'))
  vim.lsp.config.terraformls.root_dir(standalone, function(dir) chosen = dir end)
  eq(chosen, fixture .. '/standalone')

  -- Unsupported capabilities must not acquire custom buffer mappings.
  local active = { id = 99, name = 'test', supports_method = function(_, method)
    return method == 'textDocument/definition' or method == 'textDocument/references'
  end }
  active.attached_buffers = { [nested] = true }
  clients = { active }
  vim.lsp.get_client_by_id = function() return active end
  vim.api.nvim_set_current_buf(nested)
  vim.api.nvim_exec_autocmds('LspAttach', { buffer = nested, data = { client_id = 99 } })
  eq(vim.fn.maparg('grr', 'n', false, true).buffer, 1)
  eq(vim.fn.maparg('gt', 'n'), '')
  eq(vim.fn.maparg(' r', 'n'), '')
  local definition, original_definition = false, vim.lsp.buf.definition
  vim.lsp.buf.definition = function() definition = true end
  vim.fn.maparg('grt', 'n', false, true).callback()
  vim.lsp.buf.definition = original_definition
  assert(definition)

  -- Completion must trigger on identifiers, preserve server punctuation, and
  -- tolerate servers with no advertised triggers or multiple attached buffers.
  local enabled = {}
  vim.lsp.completion.enable = function(enable, id, buf, opts)
    enabled[#enabled + 1] = { enable, id, buf, opts.autotrigger }
  end
  for _, name in ipairs({ 'gopls', 'basedpyright', 'terraformls' }) do
    active.name = name
    active.settings = { python = {} }
    active.supports_method = function(_, method) return method == 'textDocument/completion' end
    active.server_capabilities = { completionProvider = name == 'basedpyright' and {} or { triggerCharacters = { '.', ':' } } }
    for _ = 1, 2 do
      vim.api.nvim_exec_autocmds('LspAttach', { buffer = nested, data = { client_id = active.id } })
    end
    local triggers = active.server_capabilities.completionProvider.triggerCharacters
    for char in ('aAzZ09_'):gmatch('.') do assert(vim.tbl_contains(triggers, char)) end
    if name ~= 'basedpyright' then
      assert(vim.tbl_contains(triggers, '.') and vim.tbl_contains(triggers, ':'))
    end
    eq(#triggers, #vim.fn.uniq(vim.fn.sort(vim.deepcopy(triggers))))
    eq(enabled[#enabled], { true, active.id, nested, true })
    eq(vim.fn.maparg('<C-Space>', 'i', false, true).callback, vim.lsp.completion.get)
  end
  eq(vim.opt.completeopt:get(), { 'menu', 'menuone', 'noselect', 'popup' })
  vim.lsp.completion.enable = saved.completion_enable

  vim.system = saved.system
  for ft, text in pairs({ go = 'package main', python = 'x = 1', terraform = 'locals {}' }) do
    vim.cmd.enew({ bang = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
    vim.bo.filetype = ft
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], ft .. ' highlighting missing')
  end
end
local ok, err = xpcall(run, debug.traceback)
for name, value in pairs(saved) do
  if name == 'completion_enable' then vim.lsp.completion.enable = value
  elseif name == 'get_clients' or name == 'get_client_by_id' then vim.lsp[name] = value else vim[name] = value end
end
vim.fn.delete(fixture, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd.cquit()
end
print('Neovim regression checks passed')
