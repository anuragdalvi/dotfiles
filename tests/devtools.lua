-- Run after scripts/setup-nvim.sh:
-- nvim --headless -i NONE '+luafile tests/devtools.lua' '+qa!'
-- Executes only code generated in temporary Go/Python/Terraform projects.
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
root = vim.uv.fs_realpath(root)
local function file(name, lines)
  local path = root .. '/' .. name
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
  return path
end
local function open(path) vim.cmd.edit(vim.fn.fnameescape(path)) end
local function wait(message, predicate, timeout)
  assert(vim.wait(timeout or 20000, predicate, 50), message)
end
local ok, err = xpcall(function()
  file('python/pyproject.toml', { '[project]', 'name = "workflow-test"', 'version = "0.0.1"' })
  local py = file('python/test_example.py', { 'def test_example():', '    assert 2 + 2 == 4' })
  open(py)
  wait('Ruff did not attach', function() return #vim.lsp.get_clients({ name = 'ruff', bufnr = 0 }) > 0 end)
  local bad = file('python/lint_example.py', { 'import os', 'print("hello")' })
  open(bad)
  wait('Ruff did not publish unused-import diagnostics', function()
    return #vim.tbl_filter(function(d) return d.code == 'F401' end, vim.diagnostic.get(0)) > 0
  end)
  print('Ruff live diagnostics passed')

  local tf = file('infra/main.tf', { 'variable "unused_example" {', '  type = string', '}' })
  file('infra/.tflint.hcl', { 'plugin "terraform" {', '  enabled = true', '  preset = "all"', '}' })
  open(tf)
  wait('TFLint did not publish module diagnostics', function()
    return #vim.tbl_filter(function(d) return (d.source or ''):lower():find('tflint', 1, true) end, vim.diagnostic.get(0)) > 0
  end)
  print('TFLint module diagnostics passed')

  local workflows = require('dotfiles.workflows')
  local test_client
  local nt = require('neotest')
  local original_setup = nt.setup
  nt.setup = function(options)
    options.consumers = { integration_probe = function(client) test_client = client; return {} end }
    original_setup(options)
  end
  local has_run = false
  local function run_test(path, adapter_name)
    open(path)
    local neotest = workflows.tests()
    if has_run then
      -- Switching projects triggers asynchronous DirChanged/BufAdd discovery.
      wait('New project tests were not discovered', function()
        for _, id in ipairs(neotest.state.adapter_ids()) do
          if id:find(adapter_name, 1, true) then
            local counts = neotest.state.status_counts(id)
            if counts and counts.total > 0 then return true end
          end
        end
        return false
      end)
    end
    local done = false
    neotest.run.run({ path, cwd = require('dotfiles.project').root() }, function() done = true end)
    wait('Test run did not finish: ' .. path, function() return done end, 60000)
    local passed = vim.wait(20000, function()
      for _, id in ipairs(neotest.state.adapter_ids()) do
        if id:find(adapter_name, 1, true) then
          local counts = neotest.state.status_counts(id)
          if counts and counts.passed > 0 and counts.failed == 0 then return true end
        end
      end
      return false
    end, 50)
    if not passed then
      for _, id in ipairs(neotest.state.adapter_ids()) do
        if id:find(adapter_name, 1, true) then
          print('Test results: ' .. vim.inspect(test_client:get_results(id)))
        end
      end
      error('No passing test result: ' .. path)
    end
    print(adapter_name .. ': real test execution passed')
    has_run = true
  end
  run_test(py, 'neotest-python')
  file('go/go.mod', { 'module example.com/workflow', 'go 1.24' })
  local go = file('go/example_test.go', { 'package main', 'import "testing"', 'func TestExample(t *testing.T) { if 2+2 != 4 { t.Fatal("bad math") } }' })
  run_test(go, 'neotest-golang')

  local dap = workflows.debug()
  local function debug_program(configuration)
    local initialized, finished = false, false
    dap.listeners.after.event_initialized.workflow_test = function() initialized = true end
    dap.listeners.after.event_exited.workflow_test = function() finished = true end
    dap.listeners.after.event_terminated.workflow_test = function() finished = true end
    dap.run(configuration)
    wait('Debugger did not initialize: ' .. configuration.type, function() return initialized end, 30000)
    wait('Debug program did not finish: ' .. configuration.type, function() return finished end, 30000)
    print(configuration.type .. ': debugger launch and exit passed')
  end
  local script = file('python/debug_example.py', { 'print("debugger test")' })
  open(script)
  debug_program({ type = 'python', request = 'launch', name = 'Python integration', program = script, cwd = root .. '/python', pythonPath = require('dotfiles.project').python() })
  local main = file('go/main.go', { 'package main', 'func main() { println("debugger test") }' })
  open(main)
  debug_program({ type = 'go', request = 'launch', name = 'Go integration', program = main, cwd = root .. '/go' })
end, debug.traceback)
if package.loaded.dap then pcall(require('dap').terminate) end
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.fn.delete(root, 'rf')
if not ok then io.stderr:write(err .. '\n'); vim.cmd.cquit() end
print('Development-tool integration checks passed')
