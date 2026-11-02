local M = {}
function M.check()
  vim.health.start('Dotfiles development tools')
  for _, tool in ipairs({ 'nvim', 'rg', 'fzf', 'fd', 'go', 'gofmt', 'gopls', 'basedpyright-langserver', 'ruff', 'terraform', 'terraform-ls', 'tflint', 'dlv', 'uv', 'tree-sitter', 'cc' }) do
    if vim.fn.executable(tool) == 1 then
      vim.health.ok(tool .. ': ' .. vim.fn.exepath(tool))
    else
      vim.health.warn(tool .. ' is missing', { 'See README.md and run scripts/setup-nvim.sh' })
    end
  end
  local python = vim.fn.stdpath('data') .. '/python-tools/bin/python'
  if vim.fn.executable(python) == 1 then
    local result = vim.system({ python, '-c', 'import pytest, debugpy' }, { text = true }):wait(3000)
    if result.code == 0 then vim.health.ok('Python test/debug tools: ' .. python)
    else vim.health.warn('pytest/debugpy unavailable in editor tools environment', { 'Run scripts/setup-nvim.sh' }) end
  else
    vim.health.warn('Python editor tools environment is missing', { 'Run scripts/setup-nvim.sh' })
  end
  vim.health.info('Current project root: ' .. require('dotfiles.project').root())
  local compatible = vim.fn.stdpath('data') .. '/delve-go124/bin/dlv'
  if vim.fn.executable(compatible) == 1 then vim.health.ok('Delve compatibility adapter: ' .. compatible)
  else vim.health.warn('Go 1.21-1.24 debug adapter missing', { 'Run scripts/setup-nvim.sh' }) end
  vim.health.info('Use :ConformInfo and :FormatInfo for formatter availability and timing')
end
vim.api.nvim_create_user_command('DotfilesHealth', function() vim.cmd('checkhealth dotfiles') end, {})
return M
