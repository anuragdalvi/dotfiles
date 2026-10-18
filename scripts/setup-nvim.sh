#!/bin/sh
# Prepare formatting tools and the parsers used by init.lua.
set -eu

# Version-manager Go launchers may expose go without exposing gofmt.
if ! command -v gofmt >/dev/null 2>&1; then
  go_root=$(go env GOROOT)
  tool_bin="$HOME/.local/bin"
  mkdir -p "$tool_bin"
  if [ -e "$tool_bin/gofmt" ] || [ -L "$tool_bin/gofmt" ]; then
    printf 'Existing %s/gofmt is not on PATH; add that directory to PATH.\n' "$tool_bin" >&2
    exit 1
  fi
  test -x "$go_root/bin/gofmt"
  ln -s "$go_root/bin/gofmt" "$tool_bin/gofmt"
fi

for tool in nvim rg fzf go gopls basedpyright-langserver terraform ruff tree-sitter cc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing required Neovim tool: %s (see README.md).\n' "$tool" >&2
    exit 1
  fi
done

# An explicit setup step keeps downloads and parser compilation off startup.
nvim --headless -i NONE \
  '+lua local ok, err = pcall(vim.cmd, "DotfilesParsers!"); if not ok then print(err); vim.cmd.cquit() end' \
  '+qa!'
