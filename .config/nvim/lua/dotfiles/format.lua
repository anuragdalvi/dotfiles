local conform = require('conform')
local imports = require('dotfiles.imports')
local M = { enabled = true, imports_enabled = true, budget_ms = 2000 }

conform.setup({
  formatters_by_ft = {
    go = { 'gofmt', lsp_format = 'fallback' },
    terraform = { 'terraform_fmt', lsp_format = 'fallback' },
    ['terraform-vars'] = { 'terraform_fmt', lsp_format = 'fallback' },
    python = function(bufnr)
      if M.imports_enabled and not vim.b[bufnr].disable_autoimports then
        return { 'ruff_imports', 'ruff_format', lsp_format = 'fallback' }
      end
      return { 'ruff_format', lsp_format = 'fallback' }
    end,
  },
  formatters = {
    ruff_imports = {
      inherit = 'ruff_fix',
      args = { 'check', '--fix', '--select', 'I,F401', '--force-exclude', '--exit-zero', '--no-cache', '--stdin-filename', '$FILENAME', '-' },
    },
  },
  format_on_save = function(bufnr)
    if not M.enabled or vim.b[bufnr].disable_autoformat then return end
    local ft = vim.bo[bufnr].filetype
    if not vim.tbl_contains({ 'go', 'terraform', 'terraform-vars', 'python' }, ft) then return end
    local started = vim.uv.hrtime()
    if M.imports_enabled and not vim.b[bufnr].disable_autoimports and imports[ft] then
      imports[ft](bufnr, math.max(100, M.budget_ms - 500))
    end
    local elapsed = (vim.uv.hrtime() - started) / 1000000
    return { timeout_ms = math.max(50, math.floor(M.budget_ms - elapsed)), lsp_format = 'fallback' }, function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.b[bufnr].dotfiles_format_ms = math.floor((vim.uv.hrtime() - started) / 1000000)
      end
    end
  end,
})

vim.api.nvim_create_user_command('FormatToggle', function()
  M.enabled = not M.enabled
  vim.notify('Format on save: ' .. (M.enabled and 'on' or 'off'))
end, {})
vim.api.nvim_create_user_command('ImportsToggle', function()
  M.imports_enabled = not M.imports_enabled
  vim.notify('Imports on save: ' .. (M.imports_enabled and 'on' or 'off'))
end, {})
vim.api.nvim_create_user_command('FormatInfo', function()
  vim.notify(('Format: %s; imports: %s; shared budget: %d ms; last save: %s ms'):format(
    tostring(M.enabled), tostring(M.imports_enabled), M.budget_ms, tostring(vim.b.dotfiles_format_ms or 'n/a')))
end, {})
vim.keymap.set('n', '<Space>uf', '<cmd>FormatToggle<CR>', { desc = 'Toggle format on save' })
vim.keymap.set('n', '<Space>ui', '<cmd>ImportsToggle<CR>', { desc = 'Toggle imports on save' })
return M
