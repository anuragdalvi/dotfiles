local M = {}
M.python_markers = { { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile' }, '.git' }

function M.root(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  if vim.bo[bufnr].filetype == 'oil' then
    local directory = require('oil').get_current_dir(bufnr)
    if directory then return vim.fs.root(directory, '.git') or directory end
  end
  if vim.b[bufnr].dotfiles_root then return vim.b[bufnr].dotfiles_root end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' or vim.bo[bufnr].buftype ~= '' then return vim.t.dotfiles_root or vim.fn.getcwd() end
  name = vim.uv.fs_realpath(name) or name
  local ft = vim.bo[bufnr].filetype
  local root
  if vim.tbl_contains({ 'go', 'gomod', 'gowork', 'gosum' }, ft) then
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = 'gopls' })
    root = clients[1] and clients[1].config.root_dir
    root = root or vim.fs.root(name, 'go.work') or vim.fs.root(name, 'go.mod')
  elseif ft == 'python' then
    root = vim.fs.root(name, M.python_markers)
  elseif ft == 'terraform' or ft == 'terraform-vars' then
    -- Terraform commands operate on a module, not on all sibling modules.
    root = vim.fs.dirname(name)
  end
  return root or vim.fs.root(name, '.git') or vim.fs.dirname(name)
end

function M.python(root)
  root = root or M.root()
  for _, dir in ipairs({ '.venv', 'venv' }) do
    local python = vim.fs.joinpath(root, dir, 'bin', 'python')
    if vim.fn.executable(python) == 1 then return python end
  end
  if vim.env.VIRTUAL_ENV then
    local python = vim.fs.joinpath(vim.env.VIRTUAL_ENV, 'bin', 'python')
    if vim.fn.executable(python) == 1 then return python end
  end
  local tools = vim.fn.stdpath('data') .. '/python-tools/bin/python'
  if vim.fn.executable(tools) == 1 then return tools end
  return vim.fn.exepath('python3')
end

local terminals = {}
function M.delve(root)
  root = type(root) == 'string' and root or M.root()
  local version = vim.system({ 'go', 'env', 'GOVERSION' }, { cwd = root, text = true }):wait(2000)
  local minor = tonumber((version.stdout or ''):match('go1%.(%d+)'))
  local compatible = vim.fn.stdpath('data') .. '/delve-go124/bin/dlv'
  if minor and minor >= 21 and minor <= 24 and vim.fn.executable(compatible) == 1 then return compatible end
  return vim.fn.exepath('dlv')
end

function M.terminal()
  local root = M.root()
  local buf = terminals[root]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      if #vim.api.nvim_tabpage_list_wins(0) > 1 then vim.api.nvim_win_hide(win) else vim.cmd.enew() end
      return
    end
    local job = vim.b[buf].terminal_job_id
    if not job or vim.fn.jobwait({ job }, 0)[1] ~= -1 then buf = nil end
  end
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    terminals[root] = buf
  end
  vim.cmd('botright 12split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.b[buf].dotfiles_root = root
  if vim.bo[buf].buftype ~= 'terminal' then
    vim.fn.jobstart(vim.o.shell, { term = true, cwd = root })
  end
  vim.cmd.startinsert()
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
  group = vim.api.nvim_create_augroup('dotfiles-project', { clear = true }),
  callback = function(event)
    if vim.bo[event.buf].buftype == '' and vim.api.nvim_buf_get_name(event.buf) ~= '' then
      vim.t.dotfiles_root = M.root(event.buf)
    end
  end,
})
vim.api.nvim_create_user_command('ProjectRoot', function() print(M.root()) end, {})
vim.api.nvim_create_user_command('ProjectTerminal', M.terminal, {})
return M
