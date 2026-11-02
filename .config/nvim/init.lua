-- Resolve modules beside this file, including when init.lua is symlinked.
local source = debug.getinfo(1, 'S').source:sub(2)
local config_dir = vim.fs.dirname(vim.uv.fs_realpath(source) or source)
vim.opt.runtimepath:prepend(config_dir)

for _, module in ipairs({
  'options', 'plugins', 'editor', 'git', 'completion', 'format',
  'search', 'keymaps', 'lsp', 'diagnostics', 'workflows', 'health',
}) do
  require('dotfiles.' .. module)
end
