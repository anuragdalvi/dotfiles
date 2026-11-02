require('oil').setup({
  columns = {},
  delete_to_trash = false,
  skip_confirm_for_simple_edits = false,
  view_options = { show_hidden = true },
  keymaps = {
    ['<C-h>'] = false,
    ['<C-l>'] = false,
  },
})

local fzf = require 'fzf-lua'
fzf.setup({
  fzf_opts = { ['--cycle'] = true },
  keymap = {
    fzf = {
      true, -- Keep the other default search bindings.
      ['up'] = 'up',
      ['down'] = 'down',
    },
  },
  defaults = {
    file_icons = false,
    git_icons = false,
  },
  files = {
    line_query = true,
  },
  lsp = {
    -- Let workspace queries finish without the default five-second timeout.
    async_or_timeout = true,
  },
})
