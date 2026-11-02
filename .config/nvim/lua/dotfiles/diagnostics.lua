local project = require('dotfiles.project')
vim.diagnostic.config({ severity_sort = true, float = { border = 'rounded', source = true }, virtual_text = { spacing = 2, prefix = '●' } })

if vim.fn.executable('ruff') == 1 then
  vim.lsp.config('ruff', {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = project.python_markers,
    on_attach = function(client) client.server_capabilities.hoverProvider = false end,
  })
  vim.lsp.enable('ruff')
end

-- TFLint's native server avoids changing editor buffers/cwd to run a CLI linter.
if vim.fn.executable('tflint') == 1 then
  vim.lsp.config('tflint', {
    cmd = { 'tflint', '--langserver' },
    filetypes = { 'terraform', 'terraform-vars' },
    root_dir = function(bufnr, on_dir) on_dir(project.root(bufnr)) end,
    handlers = {
      ['textDocument/publishDiagnostics'] = function(err, result, context, config)
        for _, diagnostic in ipairs(result and result.diagnostics or {}) do diagnostic.source = 'tflint' end
        vim.lsp.handlers['textDocument/publishDiagnostics'](err, result, context, config)
      end,
    },
  })
  vim.lsp.enable('tflint')
end

require('trouble').setup({})
vim.keymap.set('n', '<Space>xx', '<cmd>Trouble diagnostics toggle<CR>', { desc = 'Workspace diagnostics' })
vim.keymap.set('n', '<Space>xb', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', { desc = 'Buffer diagnostics' })
vim.keymap.set('n', '<Space>xq', '<cmd>Trouble qflist toggle<CR>', { desc = 'Quickfix list' })

require('which-key').setup({ delay = 300 })
require('which-key').add({
  { '<leader>s', group = 'Search' }, { '<leader>h', group = 'Git hunks' },
  { '<leader>p', group = 'Project' }, { '<leader>t', group = 'Tests' },
  { '<leader>x', group = 'Diagnostics' }, { '<leader>u', group = 'Toggles' },
  { '<leader>j', group = 'Jump history' }, { '<leader>g', group = 'Git' },
  { '<leader>z', group = 'Debug' }, { '<leader>q', group = 'Sessions' },
  { '<leader>y', group = 'Copy paths' },
})
