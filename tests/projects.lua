-- Run: nvim --headless -i NONE '+luafile tests/projects.lua' '+qa!'
local project = require('dotfiles.project')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root)
local previous_cwd = vim.fn.getcwd()
local fzf = require('fzf-lua')
local original_exec, original_grep = fzf.fzf_exec, fzf.live_grep
local function file(path, lines)
  local name = root .. '/' .. path
  vim.fn.mkdir(vim.fs.dirname(name), 'p')
  vim.fn.writefile(lines or {}, name)
  return name
end
local function open(path, ft)
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.bo.filetype = ft
end
local ok, err = xpcall(function()
  require('gitsigns').setup({ auto_attach = false })
  for _, name in ipairs({ 'gopls', 'basedpyright', 'terraformls', 'ruff', 'tflint' }) do vim.lsp.enable(name, false) end
  vim.system({ 'git', 'init', '-q', root }):wait()
  file('go/go.mod', { 'module example.com/root', 'go 1.24' })
  open(file('go/nested/main.go'), 'go')
  assert(project.root() == root .. '/go', 'Go module root not selected')
  file('python/pyproject.toml', { '[project]', 'name = "example"', 'version = "0.0.1"' })
  open(file('python/src/main.py'), 'python')
  assert(project.root() == root .. '/python', 'Python root not selected')
  file('python/.venv/bin/python', { '#!/bin/sh', 'exit 0' })
  vim.fn.setfperm(root .. '/python/.venv/bin/python', 'rwxr-xr-x')
  assert(project.python() == root .. '/python/.venv/bin/python', 'Project interpreter not preferred')
  open(file('infra/module/main.tf'), 'terraform')
  assert(project.root() == root .. '/infra/module', 'Terraform module root not selected')

  open(file('search/main.txt'), 'text')
  file('.gitignore', { 'ignored/' })
  file('ignored/nested/file.txt')
  for _, folder in ipairs({ '.venv', 'node_modules', '.terraform', 'folder with spaces/nested' }) do
    file(folder .. '/file.txt')
  end
  vim.cmd.cd('/private/tmp') -- Search must not depend on launch cwd.
  local command, options, selected
  fzf.fzf_exec = function(cmd, opts) command, options = cmd, opts end
  fzf.live_grep = function(opts) selected = opts.cwd end
  vim.fn.maparg(' sg', 'n', false, true).callback()
  assert(selected == root, 'Project search used launch cwd')
  vim.fn.maparg(' sd', 'n', false, true).callback()
  assert(options.cwd == root)
  local listing = vim.system({ 'sh', '-c', command }, { cwd = options.cwd, text = true }):wait()
  assert(listing.code == 0, listing.stderr)
  for _, excluded in ipairs({ '.venv', 'node_modules', '.terraform', 'ignored/' }) do
    assert(not listing.stdout:find(excluded, 1, true), 'Picker included ' .. excluded)
  end
  assert(listing.stdout:find('folder with spaces/nested/', 1, true))
  options.actions.default({ 'folder with spaces/nested/' })
  assert(selected == root .. '/folder with spaces/nested', 'Selected folder path was not preserved')
  options.actions.default({}) -- cancellation is harmless

  local path = file('format.py', { 'value={"a":1}' })
  open(path, 'python')
  local formatter = require('dotfiles.format')
  vim.cmd.FormatToggle()
  vim.cmd.write()
  assert(vim.fn.readfile(path)[1] == 'value={"a":1}', 'Disabled formatting changed the file')
  vim.cmd.FormatToggle()
  vim.cmd.write()
  assert(vim.fn.readfile(path)[1] == 'value = {"a": 1}', 'Formatting did not run')
  assert(vim.b.dotfiles_format_ms < formatter.budget_ms, 'Small-file save exceeded the shared time budget')
  vim.cmd.ImportsToggle()
  assert(not formatter.imports_enabled)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'import os', 'value=1' })
  vim.cmd.write()
  assert(vim.fn.readfile(path)[1] == 'import os', 'Disabled import cleanup still removed an import')
  vim.cmd.ImportsToggle()
  assert(formatter.imports_enabled)
  vim.cmd.write()
  assert(not table.concat(vim.fn.readfile(path), '\n'):find('import os', 1, true), 'Import cleanup did not resume')

  local shell = vim.o.shell
  vim.o.shell = '/bin/sh'
  project.terminal()
  vim.cmd.stopinsert()
  local terminal = vim.api.nvim_get_current_buf()
  local job = vim.b[terminal].terminal_job_id
  assert(vim.b[terminal].dotfiles_root == root)
  vim.api.nvim_chan_send(job, 'pwd\n')
  assert(vim.wait(5000, function()
    -- The long temporary path may soft-wrap across terminal rows.
    return table.concat(vim.api.nvim_buf_get_lines(terminal, 0, -1, false), ''):find(root, 1, true)
  end, 25), 'Project terminal used the wrong working directory')
  project.terminal() -- hide
  assert(vim.fn.bufwinid(terminal) == -1 and vim.fn.jobwait({ job }, 0)[1] == -1)
  project.terminal() -- reopen the same running shell
  vim.cmd.stopinsert()
  assert(vim.api.nvim_get_current_buf() == terminal and vim.b.terminal_job_id == job)
  project.terminal()
  vim.api.nvim_chan_send(job, 'exit\n')
  vim.fn.jobwait({ job }, 1000)
  vim.o.shell = shell

  -- Restore a generated session from a private fixture directory.
  local persistence = require('persistence')
  local config = require('persistence.config').options
  local sessions = config.dir
  config.dir = root .. '/sessions/'
  vim.fn.mkdir(config.dir, 'p')
  vim.cmd.tcd(root)
  persistence.save()
  local saved_file = vim.api.nvim_buf_get_name(0)
  vim.cmd.enew()
  persistence.load()
  assert(vim.api.nvim_buf_get_name(0) == saved_file, 'Session did not restore the file')
  config.dir = sessions
  print('Project roots, search, format controls/timing, persistent terminal, and session restore passed')
end, debug.traceback)
fzf.fzf_exec, fzf.live_grep = original_exec, original_grep
require('persistence').stop()
vim.cmd.cd(previous_cwd)
vim.fn.delete(root, 'rf')
if not ok then io.stderr:write(err .. '\nCurrent buffer: ' .. vim.api.nvim_buf_get_name(0) .. '\n'); vim.cmd.cquit() end
