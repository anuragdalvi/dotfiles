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
