-- Minimal Neovim configuration.
-- See the Workspace notes in the Obsidian vault for the full key reference.
--
-- Neovim's built-in package manager installs pinned plugins for browsing,
-- searching, and the VS Code colorscheme.

-- Leader key. <leader> below means <Space>.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Use nvim-tree as the file explorer instead of netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
    src = 'https://github.com/nvim-mini/mini.nvim',
  },
  {
    src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  },
  {
    src = 'https://github.com/nvim-lua/plenary.nvim',
  },
  {
    src = 'https://github.com/nvim-telescope/telescope.nvim',
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
}, { confirm = false })

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

require('octo').setup({})
require('neogit').setup({
  integrations = {
    diffview = true,
  },
})
require('gitsigns').setup({})
require('diffview').setup({})
local conform = require('conform')
conform.setup({
  formatters_by_ft = {
    go = { 'gofmt', lsp_format = 'fallback' },
    terraform = { 'terraform_fmt', lsp_format = 'fallback' },
    ['terraform-vars'] = { 'terraform_fmt', lsp_format = 'fallback' },
    python = { 'ruff_format', lsp_format = 'fallback' },
  },
  format_on_save = false,
})

require('oil').setup({
  columns = {},
  delete_to_trash = false,
  skip_confirm_for_simple_edits = false,
  view_options = { show_hidden = false },
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

-- Sync clipboard between OS and Neovim after startup.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- [[ Basic Keymaps ]]

-- Clear search highlight with Escape, per Usage.md Recovery/Search section.
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Window/split focus with Ctrl+hjkl. This matches the tmux pane-focus keys
-- (Ctrl-b h/j/k/l) so the same spatial direction keys work whether the
-- cursor is inside a tmux pane boundary or a Neovim split boundary.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus split left' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus split down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus split up' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus split right' })

-- [[ Files, search, splits — <leader> bindings from Usage.md ]]

-- <Space>e: browse the directory containing the current file with Oil.
vim.keymap.set('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'Open parent directory' })

vim.keymap.set('n', '<leader>O', '<cmd>AerialToggle!<CR>', { desc = 'Toggle code outline' })

vim.keymap.set('n', '<leader>n', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

-- <Space>f: fuzzy-find a file under the working directory.
vim.keymap.set('n', '<leader>f', fzf.files, { desc = 'Find file' })

-- <Space>s: live project-wide search with ripgrep.
vim.keymap.set('n', '<leader>s', fzf.live_grep, { desc = 'Project search' })

-- <Space>b: switch between open buffers.
vim.keymap.set('n', '<leader>b', fzf.buffers, { desc = 'Open buffers' })

-- <Space>q: select an entry from the quickfix list.
vim.keymap.set('n', '<leader>q', fzf.quickfix, { desc = 'Quickfix list' })

-- <Space>h: search Neovim's installed help.
vim.keymap.set('n', '<leader>h', fzf.helptags, { desc = 'Search help' })

-- <Space>| and <Space>-: split right / split below.
vim.keymap.set('n', '<leader>|', ':vsplit<CR>', { desc = 'Split right' })
vim.keymap.set('n', '<leader>-', ':split<CR>', { desc = 'Split below' })

-- <Space>c: close the current split.
vim.keymap.set('n', '<leader>c', ':close<CR>', { desc = 'Close split' })

-- <Space>w: save the current file.
vim.keymap.set('n', '<leader>w', ':write<CR>', { desc = 'Write file' })

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

-- Update the tmux window/pane title to the current file, so panes are easy
-- to identify from the tmux status line without opening each one.
vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Set tmux window name to the current file',
  callback = function()
    if vim.fn.exists('$TMUX') == 0 then
      return
    end
    local name = vim.fn.expand '%:t'
    if name == '' then
      name = '[No Name]'
    end
    vim.fn.system({ 'tmux', 'rename-window', name })
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
-- gopls is an external tool (see inventory doc), not a plugin. Neovim's
-- built-in LSP client talks to it directly.
if vim.fn.executable 'gopls' == 1 then
  vim.lsp.config('gopls', {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_markers = { 'go.work', 'go.mod', '.git' },
  })
  vim.lsp.enable 'gopls'
end

-- BasedPyright supplies Python completion, navigation, type checking, and
-- diagnostics. Project environments and formatting remain project-specific.
if vim.fn.executable 'basedpyright-langserver' == 1 then
  vim.lsp.config('basedpyright', {
    cmd = { 'basedpyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = {
      'pyrightconfig.json',
      'pyproject.toml',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
      '.git',
    },
  })
  vim.lsp.enable 'basedpyright'
end

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP keymaps, scoped to buffers with an attached LSP client',
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = desc })
    end

    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('gr', fzf.lsp_references, 'List references')
    map('K', vim.lsp.buf.hover, 'Hover documentation')
    map('<leader>o', fzf.lsp_document_symbols, 'Document symbols')
    map('<leader>S', fzf.lsp_live_workspace_symbols, 'Workspace symbols')
    map('<leader>r', vim.lsp.buf.rename, 'Rename symbol')
    map('<leader>a', vim.lsp.buf.code_action, 'Code actions')
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == 'basedpyright' then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end
  end,
})

vim.keymap.set('n', '<leader>F', function()
  conform.format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer' })

-- Diagnostic navigation, available even before an LSP attaches.
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1 }
end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1 }
end, { desc = 'Previous diagnostic' })

-- vim: ts=2 sts=2 sw=2 et
