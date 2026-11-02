#!/bin/sh
# Install editor tooling and parsers. Python tools use an isolated environment.
set -eu

if [ "$(uname -s)" = Darwin ]; then
  set --
  for package in fd tflint delve uv; do
    executable=$package
    if [ "$package" = delve ]; then executable=dlv; fi
    formula=$package
    if [ "$package" = tflint ]; then formula=terraform-linters/tap/tflint; fi
    if ! command -v "$executable" >/dev/null 2>&1; then set -- "$@" "$formula"; fi
  done
  if [ "$#" -gt 0 ]; then brew install "$@"; fi
fi

if ! command -v terraform-ls >/dev/null 2>&1; then
  case $(uname -s) in
    Darwin) brew install terraform-ls ;;
    *)
      printf 'Install terraform-ls using https://github.com/hashicorp/terraform-ls/blob/main/docs/installation.md\n' >&2
      exit 1
      ;;
  esac
fi

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

for tool in nvim rg fzf fd go gopls basedpyright-langserver terraform terraform-ls tflint dlv ruff uv tree-sitter cc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing required Neovim tool: %s (see README.md).\n' "$tool" >&2
    exit 1
  fi
done

python_tools="${XDG_DATA_HOME:-"$HOME/.local/share"}/nvim/python-tools"
if [ ! -x "$python_tools/bin/python" ]; then uv venv --python python3 "$python_tools"; fi
uv pip install --python "$python_tools/bin/python" 'pytest>=8,<9' 'debugpy>=1.8,<2'

# Recent Delve releases drop support for older Go toolchains. Keep a compatible
# adapter for Go 1.21-1.24 without replacing the user's global dlv or Go version.
legacy_delve="${XDG_DATA_HOME:-"$HOME/.local/share"}/nvim/delve-go124/bin"
if [ ! -x "$legacy_delve/dlv" ]; then
  mkdir -p "$legacy_delve"
  GOBIN="$legacy_delve" go install github.com/go-delve/delve/cmd/dlv@v1.24.2
fi

# An explicit setup step keeps downloads and parser compilation off startup.
nvim --headless -i NONE \
  '+lua local ok, err = pcall(vim.cmd, "DotfilesParsers!"); if not ok then print(err); vim.cmd.cquit() end' \
  '+qa!'
