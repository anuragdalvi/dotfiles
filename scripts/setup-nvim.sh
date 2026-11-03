#!/bin/sh
# Install editor tooling and parsers. Python tools use an isolated environment.
set -eu

# Keep locally installed tools available to setup and its Neovim subprocess.
tool_bin="$HOME/.local/bin"
PATH="$tool_bin:$HOME/.nix-profile/bin:$HOME/go/bin:$PATH"
export PATH

# Use the existing user Nix profile on Ubuntu hosts that already use Nix.
# This installs the missing editor tools without requiring sudo or apt repos.
if [ "$(uname -s)" = Linux ] && command -v nix >/dev/null 2>&1; then
  set --
  for package in fd terraform-ls tflint ruff tree-sitter ripgrep; do
    executable=$package
    if [ "$package" = ripgrep ]; then executable=rg; fi
    if [ "$package" = fd ] && command -v fdfind >/dev/null 2>&1; then continue; fi
    if ! command -v "$executable" >/dev/null 2>&1; then
      set -- "$@" "nixpkgs#$package"
    fi
  done
  if [ "$#" -gt 0 ]; then
    nix --extra-experimental-features 'nix-command flakes' profile install "$@"
  fi
fi

if [ "$(uname -s)" = Linux ] && ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" = 0 ]; then
      apt-get install -y fd-find
    else
      sudo apt-get install -y fd-find
    fi
  else
    printf 'Install fd or fdfind with your Linux package manager, then rerun setup.\n' >&2
    exit 1
  fi
fi

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
    Linux)
      # Official release binaries avoid adding a system-wide apt repository.
      for tool in curl unzip sha256sum; do
        if ! command -v "$tool" >/dev/null 2>&1; then
          printf 'Install %s, then rerun setup to install terraform-ls.\n' "$tool" >&2
          exit 1
        fi
      done
      case $(uname -m) in
        x86_64) terraform_arch=amd64 ;;
        aarch64|arm64) terraform_arch=arm64 ;;
        *) printf 'Unsupported terraform-ls architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
      esac
      terraform_version=0.39.1
      archive="terraform-ls_${terraform_version}_linux_${terraform_arch}.zip"
      release_url="https://releases.hashicorp.com/terraform-ls/$terraform_version"
      download_dir=$(mktemp -d)
      trap 'rm -rf "$download_dir"' EXIT
      curl -fsSL "$release_url/$archive" -o "$download_dir/$archive"
      curl -fsSL "$release_url/terraform-ls_${terraform_version}_SHA256SUMS" -o "$download_dir/checksums"
      (cd "$download_dir" && awk -v archive="$archive" '$2 == archive { print; found = 1 } END { if (!found) exit 1 }' checksums > selected-checksum && sha256sum -c selected-checksum)
      unzip -q "$download_dir/$archive" terraform-ls -d "$download_dir"
      mkdir -p "$tool_bin"
      install -m 755 "$download_dir/terraform-ls" "$tool_bin/terraform-ls"
      ;;
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
  if [ "$tool" = fd ] && command -v fdfind >/dev/null 2>&1; then continue; fi
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
