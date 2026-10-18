#!/bin/sh
set -eu

DOTFILES=${DOTFILES:-"$HOME/dotfiles"}
BACKUP_DIR=${XDG_STATE_HOME:-"$HOME/.local/state"}/dotfiles-backups/$(date +%Y%m%d-%H%M%S)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

if [ ! -d "$DOTFILES/.git" ]; then
  printf 'Expected the dotfiles repository at %s\n' "$DOTFILES" >&2
  exit 1
fi
DOTFILES=$(CDPATH= cd "$DOTFILES" && pwd -P)

link_file() {
  source=$1
  target=$2

  if [ ! -e "$source" ]; then
    printf 'Missing tracked source; leaving target unchanged: %s\n' "$source" >&2
    return 1
  fi

  mkdir -p "$(dirname "$target")"

  # Existing directory-level links can already make both paths the same file.
  if [ -e "$target" ] && [ "$source" -ef "$target" ]; then
    printf 'Already active through parent link: %s\n' "$target"
    return
  fi

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    printf 'Already linked: %s\n' "$target"
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$BACKUP_DIR/${target#"$HOME"/}"
    mkdir -p "$(dirname "$backup")"
    mv "$target" "$backup"
    printf 'Backed up %s to %s\n' "$target" "$backup"
  fi

  ln -sfn "$source" "$target"
  printf 'Linked %s\n' "$target"
}

link_file "$DOTFILES/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES/.config/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
link_file "$DOTFILES/.config/nvim/init.lua" "$CONFIG_HOME/nvim/init.lua"
link_file "$DOTFILES/.config/nvim/nvim-pack-lock.json" "$CONFIG_HOME/nvim/nvim-pack-lock.json"
link_file "$DOTFILES/.config/herdr/config.toml" "$CONFIG_HOME/herdr/config.toml"
link_file "$DOTFILES/.config/opencode/opencode.jsonc" "$CONFIG_HOME/opencode/opencode.jsonc"
link_file "$DOTFILES/.config/opencode/tui.json" "$CONFIG_HOME/opencode/tui.json"
link_file "$DOTFILES/.config/opencode/agent/reviewer.md" "$CONFIG_HOME/opencode/agent/reviewer.md"
link_file "$DOTFILES/.config/opencode/command/review.md" "$CONFIG_HOME/opencode/command/review.md"

case $(uname -s) in
  Linux)
    link_file "$DOTFILES/.config/wezterm/wezterm.lua" "$CONFIG_HOME/wezterm/wezterm.lua"
    link_file "$DOTFILES/vscode/settings.json" "$CONFIG_HOME/Code/User/settings.json"
    link_file "$DOTFILES/vscode/keybindings.json" "$CONFIG_HOME/Code/User/keybindings.json"
    if [ -d "$CONFIG_HOME/Cursor/User" ]; then
      link_file "$DOTFILES/vscode/settings.json" "$CONFIG_HOME/Cursor/User/settings.json"
      link_file "$DOTFILES/vscode/keybindings.json" "$CONFIG_HOME/Cursor/User/keybindings.json"
    fi
    ;;
  Darwin)
    link_file "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    link_file "$DOTFILES/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    if [ -d "$HOME/Library/Application Support/Cursor/User" ]; then
      link_file "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
      link_file "$DOTFILES/vscode/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
    fi
    printf 'iTerm2: enable Preferences > Profiles > Keys > Natural Text Editing.\n'
    ;;
  *)
    printf 'Unsupported OS; linked only portable configuration.\n' >&2
    ;;
esac

if command -v herdr >/dev/null 2>&1; then
  herdr integration install opencode
else
  printf 'Herdr is not installed. See README.md for the platform command.\n'
fi
