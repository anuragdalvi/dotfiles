require('sidekick').setup({
  -- Use Sidekick for the OpenCode CLI; completion stays with Blink/LSP.
  nes = { enabled = false },
  cli = {
    picker = 'fzf-lua',
    mux = { enabled = false },
    win = { layout = 'right', split = { width = 80 } },
  },
})

local function toggle_opencode()
  require('sidekick.cli').toggle({ name = 'opencode', focus = true })
end
vim.keymap.set('n', '<Space>Aa', toggle_opencode, { desc = 'Toggle OpenCode' })
vim.keymap.set({ 'n', 't' }, '<C-.>', toggle_opencode, { desc = 'Toggle OpenCode' })
vim.keymap.set('n', '<Space>Af', function()
  require('sidekick.cli').send({ name = 'opencode', msg = '{file}', submit = false })
end, { desc = 'Send file to OpenCode' })
vim.keymap.set('x', '<Space>Av', function()
  require('sidekick.cli').send({ name = 'opencode', msg = '{selection}', submit = false })
end, { desc = 'Send selection to OpenCode' })
