local function organize_go_imports(bufnr, timeout_ms)
  local deadline = vim.uv.hrtime() + timeout_ms * 1000000
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = 'gopls' })) do
    local remaining = math.floor((deadline - vim.uv.hrtime()) / 1000000)
    if remaining <= 0 then break end
    local result, err = client:request_sync('textDocument/codeAction', {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
      range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } },
      context = { only = { 'source.organizeImports' }, diagnostics = {} },
    }, remaining, bufnr)
    if err or (result and result.err) then
      vim.notify('Go imports could not be organized: ' .. vim.inspect(err or result.err), vim.log.levels.WARN)
    end
    for _, action in ipairs(result and result.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
    end
  end
end

local function add_python_imports(bufnr, timeout_ms)
  local deadline = vim.uv.hrtime() + timeout_ms * 1000000
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = 'basedpyright' })) do
    local namespaces = {}
    local prefix = ('nvim.lsp.%s.%d'):format(client.name, client.id)
    -- Include push diagnostics and dynamically registered pull providers.
    for id, info in pairs(vim.diagnostic.get_namespaces()) do
      if info.name == prefix or vim.startswith(info.name, prefix .. '.') then
        namespaces[#namespaces + 1] = id
      end
    end
    local uri = vim.uri_from_bufnr(bufnr)
    local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
    local edits, seen = {}, {}
    -- Request all fixes against one buffer version, then apply them together.
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { namespace = namespaces })) do
      if diagnostic.code == 'reportUndefinedVariable' and diagnostic.user_data and diagnostic.user_data.lsp then
        local remaining = math.floor((deadline - vim.uv.hrtime()) / 1000000)
        if remaining <= 0 then break end
        local result = client:request_sync('textDocument/codeAction', {
          textDocument = { uri = uri },
          range = diagnostic.user_data.lsp.range,
          context = { only = { 'quickfix' }, diagnostics = { diagnostic.user_data.lsp } },
        }, remaining, bufnr)
        local imports = {}
        for _, action in ipairs(result and result.result or {}) do
          if action.edit and (action.title:match('^import ') or action.title:match('^from ')) then
            imports[action.title] = action
          end
        end
        local titles = vim.tbl_keys(imports)
        if #titles == 1 then
          local changes = imports[titles[1]].edit.changes or {}
          for _, edit in ipairs(changes[uri] or {}) do
            local key = vim.json.encode(edit)
            if not seen[key] then edits[#edits + 1] = edit; seen[key] = true end
          end
        end
      end
    end
    if #edits > 0 and vim.api.nvim_buf_get_changedtick(bufnr) == changedtick then
      vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
    end
  end
end

return { go = organize_go_imports, python = add_python_imports }
