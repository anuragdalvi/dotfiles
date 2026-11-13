require('mini.ai').setup({})
require('mini.surround').setup({
  -- Keep Flash's s/S mappings immediate; surround actions live under gs.
  mappings = {
    add = 'gsa',
    delete = 'gsd',
    replace = 'gsr',
    find = 'gsf',
    find_left = 'gsF',
    highlight = 'gsh',
  },
})

require('grug-far').setup({})
vim.keymap.set('n', '<Space>sr', function()
  local root = require('dotfiles.project').root()
  require('grug-far').open({})
  -- grug-far runs its engine from the window's working directory.
  vim.cmd.lcd(vim.fn.fnameescape(root))
end, { desc = 'Search and replace in project' })

require('yanky').setup({
  ring = { history_length = 100, storage = 'shada' },
  -- The existing TextYankPost autocmd already highlights copied text.
  highlight = { on_yank = false, on_put = true, timer = 200 },
})
for keys, action in pairs({
  y = 'YankyYank',
  p = 'YankyPutAfter',
  P = 'YankyPutBefore',
  gp = 'YankyGPutAfter',
  gP = 'YankyGPutBefore',
}) do
  vim.keymap.set({ 'n', 'x' }, keys, '<Plug>(' .. action .. ')')
end
vim.keymap.set('n', '[y', '<Plug>(YankyPreviousEntry)', { desc = 'Paste older yank' })
vim.keymap.set('n', ']y', '<Plug>(YankyNextEntry)', { desc = 'Paste newer yank' })
vim.keymap.set('n', '<Space>yh', '<cmd>YankyRingHistory<CR>', { desc = 'Paste from yank history' })
