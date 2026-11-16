#!/bin/sh
# Install the CLI companions used by Zsh, tmux, and the Neovim jj integration.
set -eu
PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"
export PATH

for tool in zoxide sesh jj tmux fzf python3; do
  command -v "$tool" >/dev/null 2>&1 && continue
  if command -v brew >/dev/null 2>&1; then
    package=$tool
    [ "$tool" != python3 ] || package=python
    brew install "$package"
  elif command -v nix >/dev/null 2>&1; then
    package=$tool
    [ "$tool" != jj ] || package=jujutsu
    nix --extra-experimental-features 'nix-command flakes' profile install "nixpkgs#$package"
  else
    printf 'Install %s with your package manager, then rerun this script.\n' "$tool" >&2
    printf 'See the Workspace tools section in README.md for upstream instructions.\n' >&2
    exit 1
  fi
done
zoxide --version
sesh --version
jj --version
