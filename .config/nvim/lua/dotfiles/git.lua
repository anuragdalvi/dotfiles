-- Neogit and Diffview initialize themselves when their commands are used.
require('jj').setup({
  picker = { snacks = false }, -- Use vim.ui.select without adding Snacks.
  diff = { backend = 'native' },
})
require('diffbandit').setup({})
-- DiffBandit defaults to the buffer name, but Oil names are virtual URIs.
-- Adapt its public Git entry point so both commands and mappings use real paths.
local diffbandit = require('diffbandit')
local open_git = diffbandit.git
diffbandit.git = function(opts)
  opts = vim.tbl_extend('force', {}, opts or {})
  if vim.bo.filetype == 'oil' then
    local oil = require('oil')
    local directory = oil.get_current_dir()
    if not directory then return nil, 'DiffBandit requires a local Oil directory' end
    opts.root = opts.root or directory
    if opts.scope == 'current' then
      local path = opts.path or (opts.pathspecs and opts.pathspecs[1])
      if not path then
        local entry = oil.get_cursor_entry()
        path = entry and entry.name
      end
      if not path then return nil, 'Select a file in Oil to view its diff' end
      if not vim.startswith(path, '/') then path = vim.fs.joinpath(directory, path) end
      local stat = vim.uv.fs_stat(path)
      if not stat or stat.type ~= 'file' then return nil, 'Select a local file in Oil to view its diff' end
      opts.path = path
    end
  end
  return open_git(opts)
end
-- Compare, commit, log and branch commands resolve their repository through
-- diffbandit.git.root, which otherwise tries to cd into the oil:// buffer name.
local diffbandit_git = require('diffbandit.git')
local find_root = diffbandit_git.root
diffbandit_git.root = function(opts)
  opts = opts or {}
  if not opts.root and not opts.path and vim.bo.filetype == 'oil' then
    local directory = require('oil').get_current_dir()
    if not directory then return nil, 'DiffBandit requires a local Oil directory' end
    opts = vim.tbl_extend('force', {}, opts, { root = directory })
  end
  return find_root(opts)
end

-- Review everything this branch changed since it left the default branch.
vim.keymap.set('n', '<Space>gc', function()
  local root = require('dotfiles.project').root()
  local result = vim.system({ 'git', '-C', root, 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' }, { text = true }):wait()
  local base = result.code == 0 and vim.trim(result.stdout) or 'main'
  local ok, err = diffbandit.git_compare(base, 'HEAD', { root = root })
  if not ok and err then vim.notify('DiffBandit: ' .. tostring(err), vim.log.levels.ERROR) end
end, { desc = 'DiffBandit branch vs default branch' })
vim.keymap.set('n', '<Space>gb', '<cmd>DiffBanditGit<CR>', { desc = 'DiffBandit repository changes' })
vim.keymap.set('n', '<Space>gB', '<cmd>DiffBanditGitCurrent<CR>', { desc = 'DiffBandit current file' })
vim.keymap.set('n', '<Space>Jj', '<cmd>J log<CR>', { desc = 'Jujutsu log' })
vim.keymap.set('n', '<Space>Js', '<cmd>J status<CR>', { desc = 'Jujutsu status' })
vim.keymap.set('n', '<Space>Jd', '<cmd>J diff<CR>', { desc = 'Jujutsu diff' })
vim.keymap.set('n', '<Space>Je', '<cmd>J describe<CR>', { desc = 'Jujutsu describe change' })

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
