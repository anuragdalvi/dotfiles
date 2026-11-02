require('nvim-autopairs').setup({})

require('flash').setup({})
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash code selection' })

-- Keep database connections and saved queries outside the dotfiles repository.
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_save_location = vim.fn.stdpath('data') .. '/dadbod-ui'
vim.g.db_ui_execute_on_save = 0
vim.keymap.set('n', '<Space>D', '<cmd>DBUIToggle<CR>', { desc = 'Toggle database browser' })
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('dotfiles-sql-completion', { clear = true }),
  pattern = { 'sql', 'mysql', 'plsql' },
  callback = function(event)
    vim.bo[event.buf].omnifunc = 'vim_dadbod_completion#omni'
  end,
})

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
