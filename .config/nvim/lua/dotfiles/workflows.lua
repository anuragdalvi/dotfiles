local project = require('dotfiles.project')
local M = {}
local tests_ready, debug_ready = false, false

function M.tests()
  vim.cmd.tcd(project.root())
  if not tests_ready then
    require('neotest').setup({
      adapters = {
        require('neotest-golang')({ runner = 'go', go_test_args = { '-v', '-count=1' } }),
        require('neotest-python')({
          runner = 'pytest',
          python = function(path) return project.python(vim.fs.root(path, project.python_markers) or project.root()) end,
          dap = { justMyCode = false },
        }),
      },
    })
    tests_ready = true
  end
  return require('neotest')
end

function M.debug()
  vim.cmd.tcd(project.root())
  if not debug_ready then
    local dap, ui = require('dap'), require('dapui')
    ui.setup({})
    require('dap-go').setup({})
    local go_adapter = dap.adapters.go
    dap.adapters.go = function(callback, configuration)
      go_adapter(function(adapter)
        adapter.executable.command = project.delve(configuration.cwd)
        callback(adapter)
      end, configuration)
    end
    local adapter_python = vim.fn.stdpath('data') .. '/python-tools/bin/python'
    require('dap-python').setup(vim.fn.executable(adapter_python) == 1 and adapter_python or 'python3')
    require('dap-python').resolve_python = function() return project.python() end
    require('dap-python').test_runner = 'pytest'
    for _, ft in ipairs({ 'go', 'python' }) do
      for _, configuration in ipairs(dap.configurations[ft] or {}) do
        configuration.cwd = project.root
      end
    end
    dap.listeners.after.event_initialized.dotfiles = function() ui.open() end
    dap.listeners.before.event_terminated.dotfiles = function() ui.close() end
    dap.listeners.before.event_exited.dotfiles = function() ui.close() end
    debug_ready = true
  end
  return require('dap')
end

local function map(key, fn, desc) vim.keymap.set('n', '<Space>' .. key, fn, { desc = desc }) end
map('tt', function() M.tests().run.run({ cwd = project.root() }) end, 'Run nearest test')
map('tf', function() M.tests().run.run({ vim.api.nvim_buf_get_name(0), cwd = project.root() }) end, 'Run test file')
map('ta', function() M.tests().run.run({ project.root(), cwd = project.root() }) end, 'Run project tests')
map('tl', function() M.tests().run.run_last() end, 'Run last test')
map('ts', function() M.tests().summary.toggle() end, 'Test summary')
map('to', function() M.tests().output.open({ enter = true }) end, 'Test output')
map('tS', function() M.tests().run.stop() end, 'Stop tests')
map('td', function() M.debug(); M.tests().run.run({ strategy = 'dap', cwd = project.root() }) end, 'Debug nearest test')
map('zb', function() M.debug().toggle_breakpoint() end, 'Toggle breakpoint')
map('zc', function() M.debug().continue() end, 'Start / continue debug')
map('zn', function() M.debug().step_over() end, 'Step over')
map('zi', function() M.debug().step_into() end, 'Step into')
map('zo', function() M.debug().step_out() end, 'Step out')
map('zt', function() M.debug().terminate() end, 'Terminate debug session')
map('zu', function() M.debug(); require('dapui').toggle() end, 'Toggle debug UI')
map('ze', function() M.debug(); require('dapui').eval() end, 'Inspect expression')
vim.keymap.set('n', '<F5>', function() M.debug().continue() end, { desc = 'Debug continue' })
vim.keymap.set('n', '<F10>', function() M.debug().step_over() end, { desc = 'Debug step over' })
vim.keymap.set('n', '<F11>', function() M.debug().step_into() end, { desc = 'Debug step into' })
vim.keymap.set('n', '<S-F11>', function() M.debug().step_out() end, { desc = 'Debug step out' })

-- Session data stays in stdpath('state'); restore is explicit.
vim.opt.sessionoptions:remove({ 'options', 'globals', 'terminal' })
require('persistence').setup({ branch = true })
if #vim.api.nvim_list_uis() == 0 then require('persistence').stop() end
vim.api.nvim_create_autocmd('User', {
  pattern = 'PersistenceSavePre',
  callback = function() vim.cmd.tcd(project.root()) end,
})
map('qr', function() vim.cmd.tcd(project.root()); require('persistence').load() end, 'Restore project session')
map('qs', function() require('persistence').select() end, 'Choose saved session')
map('ql', function() require('persistence').load({ last = true }) end, 'Restore last session')
map('qx', function() require('persistence').stop() end, 'Stop session saving')
map('gd', '<cmd>DiffviewOpen<CR>', 'Working tree diff')
map('gh', '<cmd>DiffviewFileHistory %<CR>', 'File history')
map('gs', '<cmd>Neogit<CR>', 'Git status')
return M
