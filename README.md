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

This configuration requires Neovim 0.12 or newer for `vim.pack`. It uses
its native LSP client, gopls for Go, BasedPyright for Python,
and terraform-ls for Terraform. On macOS, install their supporting tools:

```sh
brew install go gopls basedpyright terraform-ls ruff tree-sitter
brew install hashicorp/tap/terraform
sh ~/dotfiles/scripts/setup-nvim.sh
```

The setup script installs missing terraform-ls on macOS, exposes gofmt when
a Go version-manager launcher leaves it off PATH, and installs the configured
Tree-sitter parsers. It requires a C compiler. On Ubuntu, install these same
executables through your package manager or their official distributions,
then run the script. Parser installation is explicit; normal startup never
downloads parsers. Use `:DotfilesParsers` to install them again after updates.

Frequent Neovim keys:

| Key | Action |
| --- | --- |
| `Space f / s / b` | Files / project search / buffers |
| `Space e / n` | Oil directory editor / project tree |
| `Space ?` | Help search |
| `Space v / -` | Split right / below (`Space \|` also splits right) |
| `Ctrl-h/j/k/l` | Focus a split |
| `Space hs / hr / hp / hb` | Stage / discard / preview hunk / blame |
| Visual `Space hs / hr` | Stage / discard selected lines |
| `[[ / ]]` | Previous / next outline symbol |
| `gd / grr / grt` | Definition / references / type definition (definition fallback) |
| `Space r / a / F` | Rename / code action / format |
| `Space o / S / O` | Document symbols / workspace symbols / outline |
| `[d / ]d / Space d` | Previous diagnostic / next diagnostic / diagnostic details |
| `Space jo / ji` | Oldest earlier / newest forward jump |

Python selects the nearest project marker, prefers that project's `.venv`
or `venv` interpreter, and otherwise uses server discovery. Use
`:LspPythonPath /path/to/python` to override an attached workspace. Keep
type-checking rules and analysis exclusions in `pyrightconfig.json` or
`pyproject.toml`. BasedPyright's default checks open files; use CI for full
project checking.

Go prefers `go.work`, then `go.mod`, and discovers its toolchain per project.
Dependency jumps reuse their originating project server; ambiguous direct
opens do not start another server to index the dependency cache. Restart
Neovim after changing a project's Go toolchain/environment. Terraform uses
the Git root to include sibling modules, with a module-directory fallback
outside Git. For unusually large repositories, configure server exclusions
per project after measuring their indexing costs.

`:Octo`, `:Neogit`, and `:DiffviewOpen` initialize their Git interfaces on
demand. Inside tmux, file switches update the pane title asynchronously;
they no longer rename the shared window.

Validate configuration changes with:

```sh
nvim --headless -i NONE '+luafile tests/nvim.lua' '+qa!'
```

Install the remaining Ubuntu tools through apt, Nix, or their official
packages. Keep credentials, SSH keys, Git identity, and host-specific work
settings outside this repository.

## Terminal Setup

On macOS, use iTerm2 and enable **Preferences > Profiles > Keys > Natural Text
Editing**. Do not create iTerm panes for project work; tmux or Herdr owns panes.

On Ubuntu, the tracked WezTerm profile disables its tab bar for the same reason.

## Workspace Keys

Herdr uses these workspace keys:

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

tmux uses its default `Ctrl-b` bindings, plus `v` to split horizontally, `q`
to detach, `x` to confirm pane closure, and `r` to reload its configuration.
Use `Ctrl-b` followed by an arrow key to focus a pane. Copy mode uses the
default Emacs keys; when vi copy mode is selected separately, `y` copies the
selection.

The shell configuration is tracked at `zshrc`. The installer links it to
`~/.zshrc`; rerun the installer after updating an existing checkout. Keep
editor selection, optional tool-manager hooks, and completions in
`~/.zshrc.local` as needed.

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
