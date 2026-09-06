# Terminal Dotfiles

Shared terminal configuration for macOS and Ubuntu. iTerm2 is the macOS
renderer and WezTerm is the Ubuntu renderer. Zsh, tmux, Neovim, Herdr, and
OpenCode use the same tracked configuration on both systems.

## Bootstrap

Clone this repository to `~/dotfiles`, then run:

```sh
sh ~/dotfiles/install.sh
```

The installer moves existing files to a timestamped directory under
`~/.local/state/dotfiles-backups/`, then creates symlinks. Re-running it leaves
correct links unchanged.

Install the core tools on macOS:

```sh
brew install zsh tmux neovim ripgrep fzf herdr
```

Install Herdr on Ubuntu with its official stable installer. Download and
inspect the script first; it verifies the selected release binary's SHA-256:

```sh
curl -fsSL https://herdr.dev/install.sh -o /tmp/herdr-install.sh
less /tmp/herdr-install.sh
sh /tmp/herdr-install.sh
herdr integration install opencode
```

Neovim installs pinned Oil `v2.16.0` and fzf-lua on first launch through its
built-in `vim.pack` manager. The tracked `.config/nvim/nvim-pack-lock.json`
keeps both operating systems on the same exact revisions.

Install the remaining Ubuntu tools through apt, Nix, or their official
packages. Keep credentials, SSH keys, Git identity, and host-specific work
settings outside this repository.

## Terminal Setup

On macOS, use iTerm2 and enable **Preferences > Profiles > Keys > Natural Text
Editing**. Do not create iTerm panes for project work; tmux or Herdr owns panes.

On Ubuntu, the tracked WezTerm profile disables its tab bar for the same reason.

## Shared Keys

tmux and Herdr share these workspace keys:

| Key | Action |
| --- | --- |
| `Ctrl-b v` | Split right |
| `Ctrl-b -` | Split down |
| `Ctrl-b h/j/k/l` | Focus left/down/up/right |
| `Ctrl-b c` | New window/tab |
| `Ctrl-b n/p` | Next/previous window/tab |
| `Ctrl-b z` | Zoom pane |
| `Ctrl-b x` | Close pane |
| `Ctrl-b [` | Copy mode |
| `Ctrl-b q` | Detach |
| `Ctrl-b ?` | Key help |

Use tmux for a normal shell/editor project session. Use Herdr instead when one
or more coding agents need status tracking, restore, or long-lived execution.
Do not run tmux inside Herdr because Herdr cannot detect agents behind tmux.

## Updates

```sh
herdr update                    # direct Herdr install only
brew upgrade                    # Homebrew-managed tools
nix profile upgrade '.*'        # Nix profile tools
opencode upgrade
```

Restart OpenCode after changing files under `.config/opencode`. Reload Herdr
with `herdr server reload-config` and tmux with `Ctrl-b r`.
