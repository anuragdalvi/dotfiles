-- Plugin browsing, search, formatting, and project language support.

-- Keep plugin-local bindings and global shortcuts on the same prefix.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Use nvim-tree as the file explorer instead of netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Empty .tf files otherwise default to TinyFugue instead of Terraform.
vim.filetype.add({ extension = { tf = 'terraform' } })

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
vim.opt.timeoutlen = 1000
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
