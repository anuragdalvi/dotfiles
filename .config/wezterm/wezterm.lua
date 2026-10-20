local wezterm = require 'wezterm'

return {
  font_size = 12.0,
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
  color_scheme = 'Tokyo Night Storm',
  window_padding = { left = 4, right = 4, top = 4, bottom = 4 },
}
