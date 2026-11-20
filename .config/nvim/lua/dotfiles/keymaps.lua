local fzf = require 'fzf-lua'
local project = require 'dotfiles.project'
-- [[ Basic Keymaps ]]

-- Clear search highlight with Escape.
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

local function copy_file_path(kind)
  local path
  if vim.bo.filetype == 'oil' then
    local oil = require('oil')
    local directory, entry = oil.get_current_dir(), oil.get_cursor_entry()
    if directory and entry then path = vim.fs.joinpath(directory, entry.name) end
  elseif vim.bo.buftype == '' then
    path = vim.api.nvim_buf_get_name(0)
  end
  if not path or path == '' then
    vim.notify('Select a local file in Oil or open a named file first.', vim.log.levels.WARN)
    return
  end
  if kind == 'relative' then path = vim.fn.fnamemodify(path, ':.') end
  if kind == 'name' then path = vim.fs.basename(path) end
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path)
end
vim.keymap.set('n', '<Space>yp', function() copy_file_path('relative') end, { desc = 'Copy relative file path' })
vim.keymap.set('n', '<Space>yP', function() copy_file_path('absolute') end, { desc = 'Copy absolute file path' })
vim.keymap.set('n', '<Space>yn', function() copy_file_path('name') end, { desc = 'Copy file name' })

-- Jump to the oldest earlier location in the current jump list.
local function jump_oldest()
  local jumps, index = unpack(vim.fn.getjumplist())
  if index > 0 then
    local ctrl_o = vim.api.nvim_replace_termcodes('<C-o>', true, false, true)
    vim.api.nvim_feedkeys(tostring(index) .. ctrl_o, 'nx', false)
  end
end

local function jump_newest()
  local jumps, index = unpack(vim.fn.getjumplist())
  local count = #jumps - index - 1
  if count > 0 then
    local ctrl_i = vim.api.nvim_replace_termcodes('<C-i>', true, false, true)
    vim.api.nvim_feedkeys(tostring(count) .. ctrl_i, 'nx', false)
  end
end
vim.keymap.set('n', '<C-S-o>', jump_oldest, { desc = 'Jump to oldest earlier location' })
vim.keymap.set('n', '<C-S-i>', jump_newest, { desc = 'Jump to newest forward location' })

-- Portable alternatives when the terminal cannot distinguish Ctrl+Shift.
vim.keymap.set('n', '<Space>jo', jump_oldest, { desc = 'Jump to oldest earlier location' })
vim.keymap.set('n', '<Space>ji', jump_newest, { desc = 'Jump to newest forward location' })

-- Ctrl+hjkl focuses splits and continues into tmux panes at the edge;
-- Alt+hjkl resizes the same way. tmux.conf holds the matching bindings.
local splits = require('smart-splits')
splits.setup({ move = { at_edge = 'stop' } })
vim.keymap.set('n', '<C-h>', splits.move_cursor_left, { desc = 'Focus split/pane left' })
vim.keymap.set('n', '<C-j>', splits.move_cursor_down, { desc = 'Focus split/pane down' })
vim.keymap.set('n', '<C-k>', splits.move_cursor_up, { desc = 'Focus split/pane up' })
vim.keymap.set('n', '<C-l>', splits.move_cursor_right, { desc = 'Focus split/pane right' })
vim.keymap.set('n', '<M-h>', splits.resize_left, { desc = 'Resize split left' })
vim.keymap.set('n', '<M-j>', splits.resize_down, { desc = 'Resize split down' })
vim.keymap.set('n', '<M-k>', splits.resize_up, { desc = 'Resize split up' })
vim.keymap.set('n', '<M-l>', splits.resize_right, { desc = 'Resize split right' })

-- <Space>e: browse the directory containing the current file with Oil.
vim.keymap.set('n', '<Space>e', '<cmd>Oil<CR>', { desc = 'Open parent directory' })

vim.keymap.set('n', '<Space>O', '<cmd>AerialToggle!<CR>', { desc = 'Toggle code outline' })

vim.keymap.set('n', '<Space>n', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

-- <Space>f: fuzzy-find a file under the working directory.
vim.keymap.set('n', '<Space>f', function() fzf.files({ cwd = project.root() }) end, { desc = 'Find file' })

-- <Space>sg: search the detected project with ripgrep.
vim.keymap.set('n', '<Space>sg', function() fzf.live_grep({ cwd = project.root() }) end, { desc = 'Project search' })

vim.keymap.set('n', '<Space>sc', function() fzf.live_grep({ cwd = vim.fn.getcwd() }) end, { desc = 'Search current directory' })

-- Choose a folder under the working directory, then search its contents.
vim.keymap.set('n', '<Space>sd', function()
  local cwd = project.root()
  local fd = require('dotfiles.tools').fd()
  if not fd then
    vim.notify('Folder search needs fd or fdfind. Run scripts/setup-nvim.sh.', vim.log.levels.WARN)
    return
  end
  fzf.fzf_exec(fd .. ' --type d --hidden --exclude .git --exclude .venv --exclude venv --exclude node_modules --exclude .terraform --exclude __pycache__ --exclude .cache', {
    cwd = cwd,
    prompt = 'Search folder> ',
    fzf_opts = { ['--no-multi'] = true },
    actions = {
      ['default'] = function(selected)
        if not selected or not selected[1] then return end
        fzf.live_grep({ cwd = vim.fs.normalize(vim.fs.joinpath(cwd, selected[1])) })
      end,
    },
  })
end, { desc = 'Choose folder to search' })

vim.keymap.set('n', '<Space>pr', '<cmd>ProjectRoot<CR>', { desc = 'Show project root' })
vim.keymap.set('n', '<Space>pc', function() vim.cmd.tcd(project.root()) end, { desc = 'Use project root as tab directory' })
local function toggle_project_terminal()
  if vim.fn.mode() == 't' then
    vim.cmd.stopinsert()
    vim.schedule(project.terminal)
  else project.terminal() end
end
vim.keymap.set({ 'n', 't' }, '<F7>', toggle_project_terminal, { desc = 'Toggle project terminal' })
vim.keymap.set('n', '<Space>T', toggle_project_terminal, { desc = 'Toggle project terminal' })
-- Preserve Ctrl-\ Ctrl-n and shell editing keys in ordinary terminals.

-- <Space>b: switch between open buffers.
vim.keymap.set('n', '<Space>b', fzf.buffers, { desc = 'Open buffers' })

-- <Space>sq: select an entry from the quickfix list.
vim.keymap.set('n', '<Space>sq', fzf.quickfix, { desc = 'Quickfix picker' })

vim.keymap.set('n', '<Space>?', fzf.helptags, { desc = 'Search help' })
vim.keymap.set('n', '<Space><Space>', fzf.resume, { desc = 'Resume last picker' })
vim.keymap.set('n', '<Space>sw', function() fzf.grep_cword({ cwd = project.root() }) end, { desc = 'Search word under cursor' })
vim.keymap.set('x', '<Space>sw', function() fzf.grep_visual({ cwd = project.root() }) end, { desc = 'Search selection' })
vim.keymap.set('n', '<Space>/', fzf.blines, { desc = 'Search buffer lines' })
vim.keymap.set('n', '<Space>so', fzf.oldfiles, { desc = 'Recent files' })
vim.keymap.set('n', '<Space>uh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  vim.notify('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled() and 'ON' or 'OFF'))
end, { desc = 'Toggle inlay hints' })

vim.keymap.set('n', '<Space>v', '<cmd>vsplit<CR>', { desc = 'Split right' })
vim.keymap.set('n', '<Space>|', '<cmd>vsplit<CR>', { desc = 'Split right' })
vim.keymap.set('n', '<Space>-', '<cmd>split<CR>', { desc = 'Split below' })
vim.keymap.set('n', '<Space>c', '<cmd>close<CR>', { desc = 'Close split' })
vim.keymap.set('n', '<Space>w', '<cmd>write<CR>', { desc = 'Write file' })

-- Structural navigation works across languages, including Python.
vim.keymap.set('n', ']]', function() require('aerial').next(vim.v.count1) end, { desc = 'Next symbol' })
vim.keymap.set('n', '[[', function() require('aerial').prev(vim.v.count1) end, { desc = 'Previous symbol' })

-- ]q/[q, ]b/[b and ]d/[d are Neovim built-ins.

-- Highlight on yank, a built-in convenience with no external dependency.
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Name this pane rather than renaming the shared window from every pane.
local last_pane_title
vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Set tmux pane title to the current file asynchronously',
  group = vim.api.nvim_create_augroup('tmux-pane-title', { clear = true }),
  callback = function()
    if not vim.env.TMUX or not vim.env.TMUX_PANE or vim.bo.buftype ~= '' then
      return
    end
    local name = vim.fn.expand '%:t'
    if name == '' or name == last_pane_title then
      return
    end
    last_pane_title = name
    vim.system({ 'tmux', 'select-pane', '-t', vim.env.TMUX_PANE, '-T', name })
  end,
})

-- [[ Search tool ]]
-- Use ripgrep for :grep when available: fast, respects .gitignore, and
-- matches the rg usage already documented for the shell.
if vim.fn.executable 'rg' == 1 then
  vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden --glob=!.git'
  vim.opt.grepformat = '%f:%l:%c:%m'
end

vim.keymap.set('n', '<Space>F', function() require('conform').format({ async = true, lsp_format = 'fallback' }) end, { desc = 'Format buffer' })
vim.keymap.set('n', '<Space>d', vim.diagnostic.open_float, { desc = 'Show diagnostic details' })
