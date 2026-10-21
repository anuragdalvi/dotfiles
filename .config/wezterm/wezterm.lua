local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font_size = 20.0
config.font = wezterm.font("Firacode Nerd Font")
config.default_prog = { '/bin/zsh', '-l' }
config.default_cwd = wezterm.home_dir
config.keys = {
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
}
config.enable_tab_bar = false
config.scrollback_lines = 10000
config.check_for_updates = false
config.color_scheme = 'Tokyo Night Storm'
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

return config
