#!/bin/sh
# Install the standalone Git UI; install.sh links its shared configuration.
set -eu

tool_bin="$HOME/.local/bin"
PATH="$tool_bin:$HOME/.nix-profile/bin:$PATH"
export PATH

if ! command -v lazygit >/dev/null 2>&1; then
  case $(uname -s) in
    Darwin)
      brew install lazygit
      ;;
    Linux)
      if command -v nix >/dev/null 2>&1; then
        nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#lazygit
      else
        for tool in curl tar sha256sum; do
          if ! command -v "$tool" >/dev/null 2>&1; then
            printf 'Install %s, then rerun setup-lazygit.sh.\n' "$tool" >&2
            exit 1
          fi
        done
        case $(uname -m) in
          x86_64) lazygit_arch=x86_64 ;;
          aarch64|arm64) lazygit_arch=arm64 ;;
          *) printf 'Unsupported Lazygit architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
        esac
        lazygit_version=0.66.2
        archive="lazygit_${lazygit_version}_linux_${lazygit_arch}.tar.gz"
        release_url="https://github.com/jesseduffield/lazygit/releases/download/v$lazygit_version"
        download_dir=$(mktemp -d)
        trap 'rm -rf "$download_dir"' 0
        curl -fsSL "$release_url/$archive" -o "$download_dir/$archive"
        curl -fsSL "$release_url/checksums.txt" -o "$download_dir/checksums.txt"
        (
          cd "$download_dir"
          awk -v archive="$archive" '$2 == archive { print; found = 1 } END { if (!found) exit 1 }' checksums.txt > selected-checksum
          sha256sum -c selected-checksum
        )
        tar -xzf "$download_dir/$archive" -C "$download_dir" lazygit
        mkdir -p "$tool_bin"
        install -m 755 "$download_dir/lazygit" "$tool_bin/lazygit"
      fi
      ;;
    *) printf 'Install Lazygit using https://github.com/jesseduffield/lazygit#installation\n' >&2; exit 1 ;;
  esac
fi

lazygit --version
if ! command -v nvim >/dev/null 2>&1; then
  printf 'Install Neovim to use Lazygit\047s configured file editor.\n' >&2
fi
