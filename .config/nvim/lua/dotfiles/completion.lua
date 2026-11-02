require('blink.cmp').setup({
  keymap = {
    preset = 'default',
    ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<C-y>'] = { 'accept', 'fallback' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<Tab>'] = { 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  },
  fuzzy = { implementation = 'lua' },
  completion = {
    list = { selection = { preselect = false, auto_insert = false } },
    documentation = { auto_show = true },
    accept = { auto_brackets = { enabled = false } }, -- nvim-autopairs owns brackets.
  },
  signature = { enabled = true },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    per_filetype = {
      sql = { 'dadbod', 'snippets', 'buffer' },
      mysql = { 'dadbod', 'snippets', 'buffer' },
      plsql = { 'dadbod', 'snippets', 'buffer' },
    },
    providers = { dadbod = { name = 'Database', module = 'vim_dadbod_completion.blink' } },
  },
})
vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
