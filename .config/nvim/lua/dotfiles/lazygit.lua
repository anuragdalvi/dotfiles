local M = {}
local sessions = {}

function M.open()
  if vim.fn.executable('lazygit') ~= 1 then
    vim.notify('Run scripts/setup-lazygit.sh to install Lazygit.', vim.log.levels.WARN)
    return
  end
  local project_root = require('dotfiles.project').root()
  local root = vim.fs.root(project_root, '.git') or project_root
  local session = sessions[root]
  if session and vim.api.nvim_buf_is_valid(session.buf)
    and vim.fn.jobwait({ session.job }, 0)[1] == -1 then
    local win = vim.fn.bufwinid(session.buf)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
      return
    end
  else
    session = { buf = vim.api.nvim_create_buf(false, true) }
    sessions[root] = session
    vim.b[session.buf].dotfiles_root = root
  end
  local win = vim.api.nvim_open_win(session.buf, true, {
    relative = 'editor', style = 'minimal', border = 'rounded',
    width = math.max(1, math.floor(vim.o.columns * 0.9)),
    height = math.max(1, math.floor(vim.o.lines * 0.85)),
    row = math.floor(vim.o.lines * 0.05), col = math.floor(vim.o.columns * 0.05),
  })
  -- In Terminal mode q belongs to Lazygit; in Normal mode q just hides it.
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = session.buf, desc = 'Hide Lazygit' })
  if not session.job then
    session.job = vim.fn.jobstart({ 'lazygit' }, {
      term = true, cwd = root,
      on_exit = function()
        vim.schedule(function()
          if sessions[root] == session then sessions[root] = nil end
          local visible = vim.fn.bufwinid(session.buf)
          if visible ~= -1 then vim.api.nvim_win_close(visible, true) end
          if vim.api.nvim_buf_is_valid(session.buf) then vim.api.nvim_buf_delete(session.buf, { force = true }) end
        end)
      end,
    })
    if session.job <= 0 then
      sessions[root] = nil
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(session.buf, { force = true })
      vim.notify('Could not start Lazygit in ' .. root, vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd.startinsert()
end

return M
