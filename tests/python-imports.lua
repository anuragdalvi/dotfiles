-- Run: nvim --headless -i NONE '+luafile tests/python-imports.lua' '+qa!'
-- Requires BasedPyright and Ruff; all edits use a temporary project.
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local function file(name, lines) vim.fn.writefile(lines, root .. '/' .. name) end
file('pyproject.toml', { '[project]', 'name = "imports-check"', 'version = "0.0.1"' })
file('helpers.py', {
  'class DotfilesImportExample: pass',
  'class DotfilesSecondExample: pass',
  'class DotfilesThirdExample: pass',
})
file('first_choice.py', { 'class DotfilesAmbiguous: pass' })
file('second_choice.py', { 'class DotfilesAmbiguous: pass' })
file('main.py', {
  'import sys', '',
  'print(json.dumps({"hello": "世界"}))',
  'print(os.getcwd())',
  'value=DotfilesImportExample()',
  'other=DotfilesAmbiguous()',
})
local function run()
  local path = root .. '/main.py'
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(20000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = 'basedpyright' }) > 0
  end, 50), 'BasedPyright did not attach')
  local function wait_missing(count)
    assert(vim.wait(20000, function()
      return #vim.tbl_filter(function(d)
        return d.code == 'reportUndefinedVariable'
      end, vim.diagnostic.get(buf)) == count
    end, 50), 'Undefined-name diagnostics did not update')
  end
  wait_missing(4)
  vim.cmd.write()
  local contents = table.concat(vim.fn.readfile(path), '\n')
  for _, expected in ipairs({ 'import json', 'import os', 'from helpers import DotfilesImportExample' }) do
    assert(contents:find(expected, 1, true), 'Missing ' .. expected .. ': ' .. contents)
  end
  assert(not contents:find('import sys', 1, true), 'Unused import retained')
  assert(not contents:find('import DotfilesAmbiguous', 1, true), 'Ambiguous import was guessed')
  assert(contents:find('value = DotfilesImportExample()', 1, true), 'Formatting did not run')
  assert(contents:find('世界', 1, true), 'Unicode text changed')
  vim.cmd.write()
  assert(contents == table.concat(vim.fn.readfile(path), '\n'), 'Repeated save changed the file')

  -- Multiple fixes may insert names into the same existing import statement.
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'from helpers import DotfilesImportExample', '',
    'a = DotfilesImportExample()',
    'b = DotfilesSecondExample()',
    'c = DotfilesThirdExample()',
  })
  wait_missing(2)
  vim.cmd.write()
  local result = vim.system({ 'ruff', 'check', '--select', 'F821,I', '--no-cache', path }, { text = true }):wait()
  assert(result.code == 0, (result.stdout or '') .. (result.stderr or ''))
  local saved = table.concat(vim.fn.readfile(path), '\n')
  assert(saved:find('from helpers import', 1, true), 'Existing module import was lost')
  print('Python import checks passed: stdlib, project, ambiguity, shared imports, cleanup, and formatting')
end
local ok, err = xpcall(run, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.fn.delete(root, 'rf')
if not ok then io.stderr:write(err .. '\n'); vim.cmd.cquit() end
