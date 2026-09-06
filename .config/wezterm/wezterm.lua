local wezterm = require 'wezterm'

return {
  default_prog = { '/bin/zsh', '-l' },
  default_cwd = wezterm.home_dir,
  keys = {
    {
      key = 't',
      mods = 'CTRL',
      action = wezterm.action.SpawnCommandInNewTab { cwd = wezterm.home_dir },
    },
    {
      key = 't',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.SpawnCommandInNewTab { cwd = wezterm.home_dir },
    },
  },
  enable_tab_bar = false,
  scrollback_lines = 10000,
  check_for_updates = false,
  colors = {
    foreground = '#d8e7f3',
    background = '#0b1f33',
    cursor_bg = '#64b5f6',
    cursor_fg = '#0b1f33',
    selection_bg = '#244f73',
    selection_fg = '#ffffff',
  },
  window_padding = { left = 4, right = 4, top = 4, bottom = 4 },
}
