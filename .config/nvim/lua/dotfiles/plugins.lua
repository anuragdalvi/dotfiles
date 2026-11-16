local plugins = {
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
  {
    src = 'https://github.com/tpope/vim-dadbod',
  },
  {
    src = 'https://github.com/kristijanhusak/vim-dadbod-ui',
  },
  {
    src = 'https://github.com/kristijanhusak/vim-dadbod-completion',
  },
  {
    src = 'https://github.com/folke/flash.nvim',
  },
}
for _, src in ipairs({
  'folke/which-key.nvim', 'folke/trouble.nvim',
  'nvim-neotest/nvim-nio', 'nvim-neotest/neotest', 'nvim-neotest/neotest-python',
  'fredrikaverpil/neotest-golang', 'mfussenegger/nvim-dap', 'rcarriga/nvim-dap-ui',
  'leoluz/nvim-dap-go', 'mfussenegger/nvim-dap-python', 'folke/persistence.nvim',
  'rafamadriz/friendly-snippets',
  'nvim-mini/mini.ai', 'nvim-mini/mini.surround',
  'MagicDuck/grug-far.nvim', 'gbprod/yanky.nvim',
  'folke/sidekick.nvim',
  'NicolasGB/jj.nvim', 'CoreyKaylor/diffbandit.nvim',
}) do
  plugins[#plugins + 1] = { src = 'https://github.com/' .. src }
end
plugins[#plugins + 1] = { src = 'https://github.com/Saghen/blink.cmp', version = 'v1.7.0' }
vim.pack.add(plugins, { confirm = false })
