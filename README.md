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
The tmux configuration is linked at both `~/.tmux.conf` and its XDG path
so older Ubuntu tmux releases also load it. Git worktree checkouts are supported;
set `DOTFILES=/path/to/checkout` when installing from a different location.

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
brew install go gopls basedpyright terraform-ls ruff tree-sitter-cli fd delve uv
brew install terraform-linters/tap/tflint
brew install hashicorp/tap/terraform
sh ~/dotfiles/scripts/setup-nvim.sh
```

The setup script installs missing terraform-ls, fd, TFLint, Delve, and uv on
macOS, exposes gofmt when a Go version-manager launcher leaves it off PATH,
and installs the configured Tree-sitter parsers. It creates an isolated
`python-tools` environment in Neovim's data directory with pytest and debugpy.
Project `.venv`/`venv` interpreters take precedence for tests and debugged code;
install pytest and project dependencies in those environments yourself.
It requires a C compiler. On Linux hosts with Nix, setup installs missing fd,
terraform-ls, TFLint, Ruff, Tree-sitter CLI, and ripgrep into the user profile.
On Ubuntu without Nix, it installs missing `fd-find` through apt (using sudo
when needed) and installs the official terraform-ls 0.39.1 binary in
`~/.local/bin` after verifying its SHA-256 checksum. Install the remaining
executables through your package manager or their official distributions,
then run the script. Parser installation is explicit; normal startup never
downloads parsers. Use `:DotfilesParsers` to install them again after updates.
Ubuntu's `fd-find` package provides `fdfind`; setup, folder search, and health
checks accept either `fd` or `fdfind`. For Neovim system clipboard access on
Ubuntu, install `wl-clipboard` for Wayland or `xclip` for X11. macOS uses its
built-in clipboard tools. Stock Ubuntu Neovim packages may be older than the
required version; check `nvim --version` before running setup.

Shared VS Code settings use tool discovery instead of user-specific extension
and Minikube paths. Keep any local YAML schema registrations and executable
overrides in machine-local or project settings.

Frequent Neovim keys:

| Key | Action |
| --- | --- |
| `Space f / b` | Files / buffers |
| `Space s g` | Search project contents |
| `Space s d` | Choose a folder, then search its contents |
| `Space s q` | Quickfix picker |
| `Space e / n` | Oil directory editor / project tree |
| `Space D` | Toggle database browser (Dadbod UI) |
| `s / S` | Flash text jump / Tree-sitter code selection |
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
| `Space y p / y P / y n` | Copy relative path / absolute path / filename (also in Oil) |
| `Space p r / p c` | Show project root / set tab directory to root |
| `Ctrl-\` | Toggle a persistent 12-line project terminal |
| `Space x x / x b / x q` | Workspace diagnostics / buffer diagnostics / quickfix panel |
| `Space t t / t f / t a / t l` | Run nearest test / file / project / last test |
| `Space t s / t o / t S / t d` | Test summary / output / stop / debug nearest test |
| `Space z b / z c / z t` | Breakpoint / start or continue debug / terminate debug |
| `Space z n / z i / z o` | Step over / into / out |
| `Space z u / z e` | Debug UI / inspect expression |
| `F5 / F10 / F11 / Shift-F11` | Debug continue / over / into / out |
| `Space q r / q s / q l / q x` | Restore project session / choose session / restore last / stop saving |
| `Space g d / g h / g s` | Diffview / file history / Neogit |
| `Space u f / u i` | Toggle format-on-save / import changes on save |
| `Ctrl-Space` (insert mode) | Request completion (LSP, snippets, paths, SQL) |
| `Ctrl-n / Ctrl-p / Ctrl-y` (completion menu) | Next / previous / accept suggestion |
| `Tab / Shift-Tab` (snippet) | Next / previous placeholder |

Press Space and pause to see available shortcuts in WhichKey. `Space s` and
`Space q` are now groups, so project search is `Space s g` and the quickfix
picker is `Space s q`; a complete action no longer overlaps those prefixes.
Blink provides completion across language servers, paths, buffer words,
friendly-snippets, and Dadbod, with no automatic suggestion selection.

Path-copy shortcuts use the current file, or the entry under the cursor in
Oil, and copy to the system clipboard. Relative paths are relative to `:pwd`.

In search pickers, Up and Down move through results and wrap between the
first and last result, including the folder picker opened by `Space s d`.

For Flash navigation, press `s` in Normal mode, type a few characters from
the target text, then press its displayed label to jump there. Press `S`
to select a labeled code structure, or Escape to cancel. These mappings
also work in Visual and operator-pending modes; `Space s g` opens project search.

Database browsing uses `vim-dadbod`, `vim-dadbod-ui`, and
`vim-dadbod-completion`. Open it with `Space D`, then use `A` in the drawer
or `:DBUIAddConnection` to add a connection. Connection examples:
`sqlite:/absolute/path/database.sqlite3`, `duckdb:/absolute/path/database.duckdb`,
or `postgresql://localhost/database`. The database's command-line client must
be installed (`sqlite3`, `duckdb`, or `psql`, respectively). Saved connections
and queries live under Neovim's data directory, outside this repository.
In SQL buffers, `Ctrl-Space` requests table/column completion; `Ctrl-n` and
`Ctrl-p` select a suggestion, and `Ctrl-y` accepts it. Saving queries does
not execute them automatically; press `Space S` in a Dadbod query buffer
to run the query (or the selected SQL in Visual mode).

Completion suggestions appear automatically while typing. Suggestions stay
unselected until you choose one.
Braces, parentheses, brackets, and quotes close automatically. Typing the
closing character moves past it; Backspace inside an empty pair removes both.

Saving with `:w` or `Space w` formats Go with `gofmt`, Terraform (including
`.tfvars`) with `terraform fmt`, and Python with `ruff format`. Formatting
finishes before the file is written. Use `Space F` to format manually and
`:ConformInfo` to check formatter availability or errors. Import requests and
formatting share a two-second save budget, reserving time for formatting.
`:FormatInfo` shows the last save duration. Use `:FormatToggle` and
`:ImportsToggle` (or `Space u f`/`Space u i`) to control them independently;
buffer variables `disable_autoformat` and `disable_autoimports` disable them
for just the current file. When import resolution exceeds the budget, accept
an import completion or use a code action after the server finishes indexing.
With gopls attached, saving Go also adds missing imports and removes unused
imports before formatting. Accepting an unimported package completion with
`Ctrl-y` can add its import immediately; typing a reference manually is
handled on save.
Python enables BasedPyright auto-import completions as well. Saving adds
unambiguous import fixes for reported undefined names, then Ruff sorts
imports, removes unused ones, and formats the file. Missing-import fixes
require BasedPyright diagnostics to be ready. For names with multiple import
choices, use `Space a` on the name or accept a completion with `Ctrl-y`.

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
the directory containing the `.tf`/`.tfvars` file as its module root.
Searches, project terminals, test commands, and debug launch configurations
use the project helper in `lua/dotfiles/project.lua`: Go workspace/module,
nearest Python project marker, Terraform module directory, otherwise Git
root or the file directory. `:ProjectRoot` displays the result. Folder search
uses fd, respects ignore files, and excludes dependency/cache directories.
For unusually large repositories, configure server exclusions
per project after measuring their indexing costs.

Ruff supplies live Python lint diagnostics alongside BasedPyright type
checking. TFLint runs as a native language server per Terraform module.
For cloud-specific TFLint rules, declare plugins in the project's
`.tflint.hcl` and run `tflint --init` there. `Space x x` opens the diagnostics
panel. `:DotfilesHealth` (or `:checkhealth dotfiles`) reports missing tools.

Neotest and the debug adapters initialize on first use. Tests use Go's test
runner and Python's pytest. Debugging uses Delve and debugpy; local and
activated Python environments take precedence over the editor tools environment.
The bootstrap also installs an isolated Delve v1.24.2 for Go 1.21-1.24; debug
launches select it for those toolchains and otherwise use `dlv` from PATH.
Persistence saves file layouts and cursor positions on exit, with sessions
separated by project directory and Git branch. Restore explicitly with
`Space q r`; no session is restored automatically. Terminals are excluded
from saved sessions. Closing/hiding a project terminal preserves its running
shell until Neovim exits.

`init.lua` loads modules under `.config/nvim/lua/dotfiles/`: plugin declarations,
editor settings, Git, completion, imports/formatting, project roots/search,
keymaps, language servers, diagnostics, workflows, and health checks. It
resolves its own real path so modules work when init.lua is symlinked.

`:Octo`, `:Neogit`, and `:DiffviewOpen` initialize their Git interfaces on
demand. Inside tmux, file switches update the pane title asynchronously;
they no longer rename the shared window.

Validate configuration changes with:

```sh
nvim --headless -i NONE '+luafile tests/nvim.lua' '+qa!'
nvim --headless -i NONE '+luafile tests/python-imports.lua' '+qa!'
nvim --headless -i NONE '+luafile tests/projects.lua' '+qa!'
nvim --headless -i NONE '+luafile tests/devtools.lua' '+qa!'
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
