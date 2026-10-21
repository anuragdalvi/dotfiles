-- Plugin browsing, search, formatting, and project language support.

-- Keep plugin-local bindings and global shortcuts on the same prefix.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Use nvim-tree as the file explorer instead of netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Empty .tf files otherwise default to TinyFugue instead of Terraform.
vim.filetype.add({ extension = { tf = 'terraform' } })

vim.pack.add({
  {
    src = 'https://github.com/stevearc/oil.nvim',
    version = 'v2.16.0',
  },
  {
    src = 'https://github.com/ibhagwan/fzf-lua',
    version = '05e44d38de0a79c11fba5f7bf8138791b1dbdd1e',
  },
  {
    src = 'https://github.com/Mofiqul/vscode.nvim',
  },
  {
    src = 'https://github.com/lukas-reineke/indent-blankline.nvim',
  },
  {
    src = 'https://github.com/zyudneko/indent-rainbowline.nvim',
  },
  {
    src = 'https://github.com/stevearc/aerial.nvim',
  },
  {
    src = 'https://github.com/nvim-tree/nvim-tree.lua',
  },
  {
    src = 'https://github.com/nvim-tree/nvim-web-devicons',
  },
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter',
  },
  {
    src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  },
  {
    src = 'https://github.com/nvim-lua/plenary.nvim',
  },
  {
    src = 'https://github.com/pwntester/octo.nvim',
  },
  {
    src = 'https://github.com/NeogitOrg/neogit',
  },
  {
    src = 'https://github.com/lewis6991/gitsigns.nvim',
  },
  {
    src = 'https://github.com/sindrets/diffview.nvim',
  },
  {
    src = 'https://github.com/stevearc/conform.nvim',
  },
  {
    src = 'https://github.com/windwp/nvim-autopairs',
  },
}, { confirm = false })

require('nvim-autopairs').setup({})

require('vscode').setup({
  style = 'dark',
  transparent = false,
  italic_comments = true,
  terminal_colors = true,
})
vim.cmd.colorscheme 'vscode'

require('ibl').setup(require('indent-rainbowline').make_opts({}))

require('aerial').setup({
  backends = { 'treesitter', 'lsp', 'markdown' },
  nerd_font = true,
  layout = {
    default_direction = 'right',
  },
})

require('nvim-tree').setup({
  disable_netrw = true,
  hijack_cursor = true,
  update_focused_file = {
    enable = true,
    update_root = true,
  },
  view = {
    side = 'left',
    width = 32,
  },
  renderer = {
    highlight_git = true,
    highlight_opened_files = 'name',
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
  },
})

require('render-markdown').setup({})

-- Install these once with :DotfilesParsers (also run by the tool bootstrap).
-- Missing parsers fall back to syntax highlighting without startup downloads.
local parser_languages = { 'go', 'gomod', 'gowork', 'gosum', 'python', 'hcl', 'terraform', 'lua', 'vim', 'vimdoc', 'markdown', 'markdown_inline' }
vim.api.nvim_create_user_command('DotfilesParsers', function(opts)
  local treesitter = require('nvim-treesitter')
  local task = treesitter.install(parser_languages)
  if opts.bang then
    task:wait(300000)
    local installed = treesitter.get_installed()
    for _, language in ipairs(parser_languages) do
      assert(vim.tbl_contains(installed, language), 'Parser installation failed: ' .. language)
    end
  end
end, { bang = true, desc = 'Install parsers (! waits and verifies installation)' })
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('dotfiles-treesitter', { clear = true }),
  pattern = { 'go', 'gomod', 'gowork', 'gosum', 'python', 'terraform', 'terraform-vars', 'hcl', 'lua', 'vim', 'help', 'markdown' },
  callback = function(event)
    -- Avoid attaching additional parsers to large or generated buffers.
    if vim.bo[event.buf].buftype ~= '' or vim.api.nvim_buf_line_count(event.buf) > 20000 then return end
    local name = vim.api.nvim_buf_get_name(event.buf)
    local stat = name ~= '' and vim.uv.fs_stat(name) or nil
    if stat and stat.size > 1024 * 1024 then return end
    pcall(vim.treesitter.start, event.buf)
  end,
})

-- Neogit and Diffview initialize themselves when their commands are used.
-- Octo needs setup to register its commands; defer it until first use.
local function load_octo()
  if vim.g.dotfiles_octo_loaded then return end
  require('octo').setup({ picker = 'fzf-lua' })
  vim.g.dotfiles_octo_loaded = true
end
vim.api.nvim_create_user_command('Octo', function(opts)
  load_octo()
  local command = { cmd = 'Octo', args = opts.fargs, mods = opts.smods }
  if opts.range > 0 then command.range = { opts.line1, opts.line2 } end
  vim.api.nvim_cmd(command, {})
end, {
  nargs = '*', range = true, desc = 'GitHub issues and pull requests',
  complete = function(_, line)
    load_octo()
    return vim.fn.getcompletion(line, 'cmdline')
  end,
})
vim.api.nvim_create_autocmd('BufReadCmd', {
  pattern = 'octo://*', once = true,
  callback = function(event)
    load_octo()
    vim.api.nvim_exec_autocmds('BufReadCmd', { buffer = event.buf, modeline = false })
  end,
})
require('gitsigns').setup({})

-- Hunk navigation and per-hunk accept/reject, for reviewing agent changes.
-- <Space>hs stages (accept) and <Space>hr resets (discard) the hunk under the
-- cursor; visual-mode variants stage/reset the selection.
local gitsigns_keymap = function(cmd)
  return function() vim.cmd('Gitsigns ' .. cmd) end
end
vim.keymap.set('n', ']h', function() require('gitsigns').nav_hunk('next') end, { desc = 'Next git hunk' })
vim.keymap.set('n', '[h', function() require('gitsigns').nav_hunk('prev') end, { desc = 'Previous git hunk' })
vim.keymap.set('n', '<leader>hp', gitsigns_keymap('preview_hunk'), { desc = 'Preview git hunk' })
vim.keymap.set('n', '<leader>hs', gitsigns_keymap('stage_hunk'), { desc = 'Accept hunk (stage)' })
vim.keymap.set('n', '<leader>hr', gitsigns_keymap('reset_hunk'), { desc = 'Discard hunk (reset)' })
local function selected_hunk(action)
  return function()
    local first, last = vim.fn.line('v'), vim.fn.line('.')
    require('gitsigns')[action]({ math.min(first, last), math.max(first, last) })
  end
end
vim.keymap.set('x', '<leader>hs', selected_hunk('stage_hunk'), { desc = 'Accept selection (stage)' })
vim.keymap.set('x', '<leader>hr', selected_hunk('reset_hunk'), { desc = 'Discard selection (reset)' })
vim.keymap.set('n', '<leader>hb', gitsigns_keymap('blame_line'), { desc = 'Blame line' })

local conform = require('conform')
local function organize_go_imports(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = 'gopls' })) do
    local result, err = client:request_sync('textDocument/codeAction', {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
      range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
      context = { only = { 'source.organizeImports' }, diagnostics = {} },
    }, 2000, bufnr)
    if err or (result and result.err) then
      vim.notify('Go imports could not be organized: ' .. vim.inspect(err or result.err), vim.log.levels.WARN)
    end
    for _, action in ipairs(result and result.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
    end
  end
end

local function add_python_imports(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = 'basedpyright' })) do
    local namespaces = {}
    local prefix = ('nvim.lsp.%s.%d'):format(client.name, client.id)
    -- Include push diagnostics and dynamically registered pull providers.
    for id, info in pairs(vim.diagnostic.get_namespaces()) do
      if info.name == prefix or vim.startswith(info.name, prefix .. '.') then
        namespaces[#namespaces + 1] = id
      end
    end
    local uri = vim.uri_from_bufnr(bufnr)
    local edits, seen = {}, {}
    -- Request all fixes against one buffer version, then apply them together.
    local deadline = vim.uv.hrtime() + 2000 * 1000000
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { namespace = namespaces })) do
      if diagnostic.code == 'reportUndefinedVariable' and diagnostic.user_data and diagnostic.user_data.lsp then
        local remaining = math.floor((deadline - vim.uv.hrtime()) / 1000000)
        if remaining <= 0 then break end
        local result = client:request_sync('textDocument/codeAction', {
          textDocument = { uri = uri },
          range = diagnostic.user_data.lsp.range,
          context = { only = { 'quickfix' }, diagnostics = { diagnostic.user_data.lsp } },
        }, remaining, bufnr)
        local imports = {}
        for _, action in ipairs(result and result.result or {}) do
          if action.edit and (action.title:match('^import ') or action.title:match('^from ')) then
            imports[action.title] = action
          end
        end
        local titles = vim.tbl_keys(imports)
        if #titles == 1 then
          local changes = imports[titles[1]].edit.changes or {}
          for _, edit in ipairs(changes[uri] or {}) do
            local key = vim.json.encode(edit)
            if not seen[key] then edits[#edits + 1] = edit; seen[key] = true end
          end
        end
      end
    end
    if #edits > 0 then vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding) end
  end
end

conform.setup({
  formatters_by_ft = {
    go = { 'gofmt', lsp_format = 'fallback' },
    terraform = { 'terraform_fmt', lsp_format = 'fallback' },
    ['terraform-vars'] = { 'terraform_fmt', lsp_format = 'fallback' },
    python = { 'ruff_imports', 'ruff_format', lsp_format = 'fallback' },
  },
  formatters = {
    ruff_imports = {
      inherit = 'ruff_fix',
      args = { 'check', '--fix', '--select', 'I,F401', '--force-exclude', '--exit-zero', '--no-cache', '--stdin-filename', '$FILENAME', '-' },
    },
  },
  format_on_save = function(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if filetype == 'go' then organize_go_imports(bufnr) end
    if filetype == 'python' then add_python_imports(bufnr) end
    if vim.tbl_contains({ 'go', 'terraform', 'terraform-vars', 'python' }, filetype) then
      return { timeout_ms = 2000, lsp_format = 'fallback' }
    end
  end,
})

require('oil').setup({
  columns = {},
  delete_to_trash = false,
  skip_confirm_for_simple_edits = false,
  view_options = { show_hidden = true },
  keymaps = {
    ['<C-h>'] = false,
    ['<C-l>'] = false,
  },
})

local fzf = require 'fzf-lua'
fzf.setup({
  defaults = {
    file_icons = false,
    git_icons = false,
  },
  files = {
    line_query = true,
  },
  lsp = {
    -- Let workspace queries finish without the default five-second timeout.
    async_or_timeout = true,
  },
})

-- [[ Options ]]
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '▏ ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.path:append '**'
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup' }

-- Sync clipboard between OS and Neovim after startup.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- [[ Basic Keymaps ]]

-- Clear search highlight with Escape, per Usage.md Recovery/Search section.
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Jump to the oldest earlier location in the current jump list.
local function jump_oldest()
  local jumps, index = unpack(vim.fn.getjumplist())
  if index > 0 then
    local ctrl_o = vim.api.nvim_replace_termcodes('<C-o>', true, false, true)
    vim.api.nvim_feedkeys(tostring(index) .. ctrl_o, 'nx', false)
  end
end

local function jump_newest()
  local jumps, index = unpack(vim.fn.getjumplist())
  local count = #jumps - index - 1
  if count > 0 then
    local ctrl_i = vim.api.nvim_replace_termcodes('<C-i>', true, false, true)
    vim.api.nvim_feedkeys(tostring(count) .. ctrl_i, 'nx', false)
  end
end
vim.keymap.set('n', '<C-S-o>', jump_oldest, { desc = 'Jump to oldest earlier location' })
vim.keymap.set('n', '<C-S-i>', jump_newest, { desc = 'Jump to newest forward location' })

-- Portable alternatives when the terminal cannot distinguish Ctrl+Shift.
vim.keymap.set('n', '<Space>jo', jump_oldest, { desc = 'Jump to oldest earlier location' })
vim.keymap.set('n', '<Space>ji', jump_newest, { desc = 'Jump to newest forward location' })

-- Window/split focus with Ctrl+hjkl, using Vim's spatial direction keys.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus split left' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus split down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus split up' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus split right' })

-- <Space>e: browse the directory containing the current file with Oil.
vim.keymap.set('n', '<Space>e', '<cmd>Oil<CR>', { desc = 'Open parent directory' })

vim.keymap.set('n', '<Space>O', '<cmd>AerialToggle!<CR>', { desc = 'Toggle code outline' })

vim.keymap.set('n', '<Space>n', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

-- <Space>f: fuzzy-find a file under the working directory.
vim.keymap.set('n', '<Space>f', fzf.files, { desc = 'Find file' })

-- <Space>s: live project-wide search with ripgrep.
vim.keymap.set('n', '<Space>s', fzf.live_grep, { desc = 'Project search' })

-- Choose a folder under the working directory, then search its contents.
vim.keymap.set('n', '<Space>sd', function()
  local cwd = vim.fn.getcwd()
  fzf.fzf_exec('find . -type d -name .git -prune -o -type d -print', {
    cwd = cwd,
    prompt = 'Search folder> ',
    fzf_opts = { ['--no-multi'] = true },
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then return end
        fzf.live_grep({ cwd = vim.fs.normalize(vim.fs.joinpath(cwd, selected[1])) })
      end,
    },
  })
end, { desc = 'Choose folder to search' })

-- <Space>b: switch between open buffers.
vim.keymap.set('n', '<Space>b', fzf.buffers, { desc = 'Open buffers' })

-- <Space>q: select an entry from the quickfix list.
vim.keymap.set('n', '<Space>q', fzf.quickfix, { desc = 'Quickfix list' })

vim.keymap.set('n', '<Space>?', fzf.helptags, { desc = 'Search help' })

vim.keymap.set('n', '<Space>v', '<cmd>vsplit<CR>', { desc = 'Split right' })
vim.keymap.set('n', '<Space>|', '<cmd>vsplit<CR>', { desc = 'Split right' })
vim.keymap.set('n', '<Space>-', '<cmd>split<CR>', { desc = 'Split below' })
vim.keymap.set('n', '<Space>c', '<cmd>close<CR>', { desc = 'Close split' })
vim.keymap.set('n', '<Space>w', '<cmd>write<CR>', { desc = 'Write file' })

-- Structural navigation works across languages, including Python.
vim.keymap.set('n', ']]', function() require('aerial').next(vim.v.count1) end, { desc = 'Next symbol' })
vim.keymap.set('n', '[[', function() require('aerial').prev(vim.v.count1) end, { desc = 'Previous symbol' })

-- Quickfix navigation, per Usage.md.
vim.keymap.set('n', ']q', ':cnext<CR>', { desc = 'Next quickfix result' })
vim.keymap.set('n', '[q', ':cprev<CR>', { desc = 'Previous quickfix result' })

-- Highlight on yank, a built-in convenience with no external dependency.
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Name this pane rather than renaming the shared window from every pane.
local last_pane_title
vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Set tmux pane title to the current file asynchronously',
  group = vim.api.nvim_create_augroup('tmux-pane-title', { clear = true }),
  callback = function()
    if not vim.env.TMUX or not vim.env.TMUX_PANE or vim.bo.buftype ~= '' then
      return
    end
    local name = vim.fn.expand '%:t'
    if name == '' or name == last_pane_title then
      return
    end
    last_pane_title = name
    vim.system({ 'tmux', 'select-pane', '-t', vim.env.TMUX_PANE, '-T', name })
  end,
})

-- [[ Search tool ]]
-- Use ripgrep for :grep when available: fast, respects .gitignore, and
-- matches the rg usage already documented for the shell.
if vim.fn.executable 'rg' == 1 then
  vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden --glob=!.git'
  vim.opt.grepformat = '%f:%l:%c:%m'
end

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

-- terraform-ls supplies navigation, completion, and validation for
-- Terraform. tflint (also installed) runs from the shell.
if vim.fn.executable 'terraform-ls' == 1 then
  vim.lsp.config('terraformls', {
    cmd = { 'terraform-ls', 'serve' },
    filetypes = { 'terraform', 'terraform-vars' },
    -- Prefer the repository so sibling local modules remain discoverable.
    -- Outside Git, use an initialized module or the nearest .tf directory.
    root_dir = function(bufnr, on_dir)
      local filename = vim.api.nvim_buf_get_name(bufnr)
      on_dir(vim.fs.root(filename, '.git') or vim.fs.root(filename, '.terraform') or vim.fs.dirname(filename))
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

    if client:supports_method('textDocument/completion', event.buf) then
      -- Native autotrigger otherwise only fires on server punctuation (e.g. '.').
      -- Keep those triggers and also offer suggestions while typing names.
      local provider = client.server_capabilities.completionProvider
      local triggers = provider.triggerCharacters or {}
      for char in ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'):gmatch('.') do
        if not vim.tbl_contains(triggers, char) then triggers[#triggers + 1] = char end
      end
      provider.triggerCharacters = triggers
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
      vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { buffer = event.buf, desc = 'LSP completion' })
    end
  end,
})

vim.keymap.set('n', '<Space>F', function()
  conform.format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer' })

vim.keymap.set('n', '<Space>d', vim.diagnostic.open_float, { desc = 'Show diagnostic details' })
