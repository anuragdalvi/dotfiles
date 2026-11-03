local M = {}

-- Ubuntu's fd-find package names the executable fdfind.
function M.fd()
  for _, name in ipairs({ 'fd', 'fdfind' }) do
    if vim.fn.executable(name) == 1 then return name end
  end
end

return M
