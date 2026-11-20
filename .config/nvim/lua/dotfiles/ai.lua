local M = {}
require('sidekick').setup({
  -- Use Sidekick for the OpenCode CLI; completion stays with Blink/LSP.
  nes = { enabled = false },
  cli = {
    picker = 'fzf-lua',
    mux = { enabled = true, backend = 'tmux', create = 'terminal' },
    -- Sidekick attaches a managed tmux session in its terminal. Clear the
    -- outer TMUX marker so that client attachment is allowed inside Neovim.
    tools = { opencode = { env = { TMUX = '' } } },
    win = { layout = 'right', split = { width = 80 } },
  },
})

local function options()
  for _, executable in ipairs({ 'tmux', 'opencode' }) do
    if vim.fn.executable(executable) ~= 1 then
      vim.notify('Install ' .. executable .. ' to use the persistent worktree agent.', vim.log.levels.ERROR)
      return
    end
  end
  local directory = require('dotfiles.project').root()
  vim.cmd.tcd(vim.fn.fnameescape(vim.fs.root(directory, '.git') or directory))
  local state = require('sidekick.cli.state')
  -- Never send context to an agent belonging to a different worktree.
  local filter = { name = 'opencode', cwd = true, external = false }
  if #state.get(filter) == 0 then
    -- Start this tool explicitly: the CLI picker also lists agents in other
    -- directories, and its cwd filter excludes tools not started yet.
    state.attach({ tool = require('sidekick.config').get_tool('opencode') }, { show = false, focus = false })
  end
  return { name = 'opencode', filter = filter, focus = true }
end
function M.open()
  local opts = options()
  if opts then require('sidekick.cli').show(opts) end
end
function M.toggle()
  local opts = options()
  if opts then require('sidekick.cli').toggle(opts) end
end
local function send(message)
  local opts = options()
  if opts then require('sidekick.cli').send(vim.tbl_extend('force', opts, { msg = message, submit = false })) end
end
vim.keymap.set('n', '<Space>Aa', M.toggle, { desc = 'Toggle worktree OpenCode' })
vim.keymap.set({ 'n', 't' }, '<C-.>', M.toggle, { desc = 'Toggle worktree OpenCode' })
vim.keymap.set('n', '<Space>Af', function()
  send('{file}')
end, { desc = 'Send file to OpenCode' })
vim.keymap.set('x', '<Space>Av', function()
  send('{selection}')
end, { desc = 'Send selection to OpenCode' })
vim.keymap.set('n', '<Space>An', function()
  local root = require('dotfiles.project').root()
  vim.ui.input({ prompt = 'New agent worktree branch: ' }, function(branch)
    if not branch or vim.trim(branch) == '' then return end
    -- Neovim's config dir is .../nvim; the helper is a sibling under tmux.
    local script = vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath('config')), 'tmux', 'agent-session.py')
    vim.system({ 'python3', script, '--no-switch', '--from', root, branch }, { text = true }, vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify(result.stderr or 'Workspace creation failed', vim.log.levels.ERROR)
        return
      end
      local workspace = vim.json.decode(result.stdout)
      if vim.env.TMUX then
        local switched = vim.system({ 'tmux', 'switch-client', '-t', workspace.session }, { text = true }):wait()
        if switched.code ~= 0 then vim.notify(switched.stderr, vim.log.levels.ERROR) end
      else
        vim.notify('Workspace ready: tmux attach -t ' .. workspace.session)
      end
    end))
  end)
end, { desc = 'Create agent worktree workspace' })
return M
