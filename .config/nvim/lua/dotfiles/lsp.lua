local fzf = require 'fzf-lua'
-- [[ Language support ]]
-- Keep gd useful before LspAttach, instead of silently using Neovim's
-- text-based local declaration search when no language server is attached.
vim.keymap.set('n', 'gd', function()
  local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })
  if #clients == 0 then
    local filetype = vim.bo.filetype
    vim.notify(
      'No definition language server attached for '
        .. (filetype ~= '' and filetype or 'this file')
        .. '. Check :checkhealth vim.lsp and :verbose nmap gd.',
      vim.log.levels.WARN
    )
    return
  end
  vim.lsp.buf.definition()
end, { desc = 'Go to definition' })

if vim.fn.executable 'gopls' == 1 then
  local environments, pending = {}, {}
  local origin_client
  local function inside(filename, dir)
    return dir and dir ~= '' and vim.startswith(filename, dir .. '/')
  end
  local function library_file(filename, env)
    return inside(filename, env.GOMODCACHE) or inside(filename, env.GOROOT and (env.GOROOT .. '/src'))
  end
  -- Track the source of definition jumps; client enumeration order is not
  -- a reliable way to select a project when several share the module cache.
  vim.api.nvim_create_autocmd('BufLeave', {
    group = vim.api.nvim_create_augroup('go-jump-origin', { clear = true }),
    callback = function(event)
      local clients = vim.lsp.get_clients({ name = 'gopls', bufnr = event.buf })
      if #clients == 1 then origin_client = clients[1].id end
    end,
  })
  local function reuse_library(filename, on_dir)
    local candidates = {}
    for _, client in ipairs(vim.lsp.get_clients({ name = 'gopls' })) do
      local root = client.config.root_dir
      if root and environments[root] and library_file(filename, environments[root]) then
        candidates[#candidates + 1] = client
      end
    end
    for _, client in ipairs(candidates) do
      if client.id == origin_client then on_dir(client.config.root_dir); return end
    end
    if #candidates == 1 then
      on_dir(candidates[1].config.root_dir)
    else
      vim.notify('Go dependency has no unambiguous project server; open it through a project definition jump.', vim.log.levels.WARN)
    end
  end
  local function go_root(bufnr, on_dir)
    local filename = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(bufnr)) or vim.api.nvim_buf_get_name(bufnr)
    for _, env in pairs(environments) do
      if library_file(filename, env) then reuse_library(filename, on_dir); return end
    end
    local root = vim.fs.root(filename, 'go.work') or vim.fs.root(filename, 'go.mod') or vim.fs.root(filename, '.git')
    if not root then root = vim.fs.dirname(filename) end
    if not root or root == '' then return end
    local function resolve(env)
      if not vim.api.nvim_buf_is_valid(bufnr) then return end
      local current = vim.api.nvim_buf_get_name(bufnr)
      if (vim.uv.fs_realpath(current) or current) ~= filename then return end
      if library_file(filename, env) then reuse_library(filename, on_dir) else on_dir(root) end
    end
    -- Reuse environment data only while that project's server is alive.
    -- A restart re-runs go env, picking up toolchain and environment changes.
    for _, client in ipairs(vim.lsp.get_clients({ name = 'gopls' })) do
      if client.config.root_dir == root and environments[root] then resolve(environments[root]); return end
    end
    if pending[root] then table.insert(pending[root], resolve); return end
    pending[root] = { resolve }
    vim.system({ 'go', 'env', '-json', 'GOMODCACHE', 'GOROOT' }, { text = true, cwd = root }, vim.schedule_wrap(function(result)
      local ok, env = pcall(vim.json.decode, result.stdout or '')
      if result.code ~= 0 or not ok or type(env) ~= 'table' then
        env = {}
        vim.notify('Could not discover Go environment for ' .. root .. ': ' .. (result.stderr or ''), vim.log.levels.WARN)
      end
      environments[root] = env
      local callbacks = pending[root]
      pending[root] = nil
      for _, callback in ipairs(callbacks) do callback(env) end
    end))
  end
  vim.lsp.config('gopls', {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_dir = go_root,
    settings = { gopls = { completeUnimported = true } },
  })
  vim.lsp.enable 'gopls'
end

-- BasedPyright supplies Python completion, navigation, type checking, and
-- diagnostics. Project environments and formatting remain project-specific.
if vim.fn.executable 'basedpyright-langserver' == 1 then
  vim.lsp.config('basedpyright', {
    cmd = { 'basedpyright-langserver', '--stdio' },
    filetypes = { 'python' },
    -- Neovim captures this table before before_init; mutate it in place so
    -- interpreter selection reaches the client and its configuration request.
    settings = {
      python = {},
      basedpyright = { analysis = { autoImportCompletions = true } },
    },
    root_markers = { {
      'pyrightconfig.json',
      'pyproject.toml',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
    }, '.git' },
    before_init = function(_, config)
      -- Prefer a project-local environment; never share a global interpreter
      -- setting across independent Python workspaces.
      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      if config.settings.python.pythonPath then return end
      local root = config.root_dir
      if not root then return end
      for _, dir in ipairs({ '.venv', 'venv' }) do
        local python = vim.fs.joinpath(root, dir, 'bin', 'python')
        if vim.fn.executable(python) == 1 then
          config.settings.python.pythonPath = python
          return
        end
      end
      -- Otherwise let BasedPyright use project config / the launch environment.
    end,
  })
  vim.lsp.enable 'basedpyright'
end

-- Terraform modules share their root with search, terminals and linting.
if vim.fn.executable 'terraform-ls' == 1 then
  vim.lsp.config('terraformls', {
    cmd = { 'terraform-ls', 'serve' },
    filetypes = { 'terraform', 'terraform-vars' },
    root_dir = function(bufnr, on_dir)
      on_dir(require('dotfiles.project').root(bufnr))
    end,
  })
  vim.lsp.enable 'terraformls'
end

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP keymaps, scoped to buffers with an attached LSP client',
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end
    local map = function(keys, func, desc, method)
      if client:supports_method(method, event.buf) then
        vim.keymap.set('n', keys, func, { buffer = event.buf, desc = desc })
      end
    end

    map('grr', fzf.lsp_references, 'List references', 'textDocument/references')
    map('K', vim.lsp.buf.hover, 'Hover documentation', 'textDocument/hover')
    map('<Space>o', fzf.lsp_document_symbols, 'Document symbols', 'textDocument/documentSymbol')
    map('<Space>S', fzf.lsp_live_workspace_symbols, 'Workspace symbols', 'workspace/symbol')
    map('<Space>r', vim.lsp.buf.rename, 'Rename symbol', 'textDocument/rename')
    map('<Space>a', vim.lsp.buf.code_action, 'Code actions', 'textDocument/codeAction')

    -- Go to type definition when the language distinguishes types (Go
    -- interfaces, Python classes); falls back to plain definition elsewhere.
    if client:supports_method('textDocument/typeDefinition', event.buf)
      or client:supports_method('textDocument/definition', event.buf) then
      vim.keymap.set('n', 'grt', function()
        if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/typeDefinition' }) > 0 then
          vim.lsp.buf.type_definition()
        else
          vim.lsp.buf.definition()
        end
      end, { buffer = event.buf, desc = 'Type definition (or definition)' })
    end

    if client.name == 'basedpyright' then
      vim.api.nvim_buf_create_user_command(event.buf, 'LspPythonPath', function(opts)
        local python = vim.fn.fnamemodify(vim.fn.expand(opts.args), ':p')
        if vim.fn.executable(python) ~= 1 then error('Not an executable Python interpreter: ' .. python) end
        client.settings.python = client.settings.python or {}
        client.settings.python.pythonPath = python
        client:notify('workspace/didChangeConfiguration', { settings = client.settings })
        vim.notify('Python interpreter: ' .. python)
      end, { nargs = 1, complete = 'file', desc = 'Set this Python workspace interpreter' })
    end


  end,
})
