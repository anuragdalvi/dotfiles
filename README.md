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
brew install zsh tmux neovim ripgrep fzf herdr lazygit
```

Install Herdr on Ubuntu with its official stable installer. Download and
inspect the script first; it verifies the selected release binary's SHA-256:

```sh
curl -fsSL https://herdr.dev/install.sh -o /tmp/herdr-install.sh
less /tmp/herdr-install.sh
sh /tmp/herdr-install.sh
herdr integration install opencode
```

## Git workflow

Use Lazygit alongside Neovim for repository status, staging, commits, branch
management, and rebasing. Gitsigns remains configured in Neovim for reviewing
and staging individual hunks while editing; Diffview is available for detailed
diffs and file history.

Install Lazygit on macOS or Ubuntu with:

```sh
sh ~/dotfiles/scripts/setup-lazygit.sh
sh ~/dotfiles/install.sh
```

Setup uses Homebrew on macOS, an existing Nix profile on Linux, or the official
Lazygit 0.66.2 Linux release binary with SHA-256 verification. Linux release
binaries install under `~/.local/bin` and do not require sudo. An existing
Lazygit installation is left in place.

Launch `lazygit` or `lg` from a repository in another Herdr/tmux pane or tab.
Run `source ~/.zshrc` once to pick up the alias in an existing shell.
The shared configuration is `.config/lazygit/config.yml`. The installer links
the XDG path on both systems and macOS's native Application Support path.
In Lazygit, `e` opens the selected file in Neovim; quit that editor with `:q`
to return to Lazygit. When Lazygit runs inside Neovim (`Space g s`), `e` instead
hides the float and opens the file in the surrounding editor; `Space g s`
brings the same Lazygit back. Use `?` for Lazygit's key help and `q` to quit.

Inside Neovim, `Space g s` opens Lazygit at the current repository root in a
floating terminal. Its normal `q` quits Lazygit and closes the float. To hide
it while keeping it running, press `Ctrl-\ Ctrl-n`, then `q`; `Space g s`
reopens the same process. Neogit is still available through `:Neogit`.

Existing Gitsigns keys stay available: `]h`/`[h` navigate hunks, `Space hp`
previews, `Space hs` stages, and `Space hr` discards the hunk. In Visual mode,
`Space hs`/`Space hr` operate on the selected lines.

## Neovim

[LazyVim](https://www.lazyvim.org/) is a useful reference for Neovim plugins,
keymaps, and configuration ideas. This repository uses its own `vim.pack`
configuration.

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
| `Space s c` | Search Neovim's current working directory (`:pwd`) |
| `Space s d` | Choose a folder, then search its contents |
| `Space s q` | Quickfix picker |
| `Space s r` | Search and replace in the detected project (grug-far) |
| `Space e / n` | Oil directory editor / project tree |
| `Space D` | Toggle database browser (Dadbod UI) |
| `s / S` | Flash text jump / Tree-sitter code selection |
| `gsa / gsd / gsr` | Add / delete / replace surrounds (mini.surround) |
| `gsf / gsF / gsh` | Find surround right / left / highlight |
| `v ia / c ia / d aa` | Select / change an argument / delete an argument with separator (mini.ai) |
| `Space ?` | Help search |
| `Space Space` | Resume the last picker with its query |
| `Space s w / s o / /` | Grep word (or Visual selection) / recent files / buffer lines |
| `]q [q / ]b [b` | Quickfix / buffer navigation (Neovim built-ins) |
| `Space v / -` | Split right / below (`Space \|` also splits right) |
| `Ctrl-h/j/k/l` (Normal mode) | Focus a split, continuing into tmux panes at the edge |
| `Alt-h/j/k/l` (Normal mode) | Resize a split (tmux panes too) |
| `Space hs / hr / hp / hb` | Stage / discard / preview hunk / blame |
| Visual `Space hs / hr` | Stage / discard selected lines |
| `[[ / ]]` | Previous / next outline symbol |
| `gd / grr / grt` | Definition / references / type definition (definition fallback) |
| `Space r / a / F` | Rename / code action / format |
| `Space o / S / O` | Document symbols / workspace symbols / outline |
| `[d / ]d / Space d` | Previous diagnostic / next diagnostic / diagnostic details |
| `Space jo / ji` | Oldest earlier / newest forward jump |
| `Space y p / y P / y n` | Copy relative path / absolute path / filename (also in Oil) |
| `Space y h` | Choose and paste from yank history |
| `Space A a` / `Ctrl-.` | Toggle OpenCode in Sidekick (Ctrl-. also works in terminal mode) |
| `Space A f` | Add the current file to OpenCode's prompt |
| `Space A n` | Create/reopen an agent worktree workspace |
| Visual `Space A v` | Add selected text to OpenCode's prompt |
| `[y / ]y` | After pasting, replace that paste with an older / newer yank |
| `Space p r / p c` | Show project root / set tab directory to root |
| `F7` / `Space T` | Toggle a persistent 12-line project terminal (F7 also works in terminal mode) |
| `Ctrl-\ Ctrl-n` | Leave terminal input mode; shell editing keys remain available |
| `Space u c` | Toggle completion for all buffers in this Neovim session |
| `Space u h` | Toggle LSP inlay hints |
| `Space x x / x b / x q` | Workspace diagnostics / buffer diagnostics / quickfix panel |
| `Space t t / t f / t a / t l` | Run nearest test / file / project / last test |
| `Space t s / t o / t S / t d` | Test summary / output / stop / debug nearest test |
| `Space z b / z c / z t` | Breakpoint / start or continue debug / terminate debug |
| `Space z n / z i / z o` | Step over / into / out |
| `Space z u / z e` | Debug UI / inspect expression |
| `F5 / F10 / F11 / Shift-F11` | Debug continue / over / into / out |
| `Space q r / q s / q l / q x` | Restore project session / choose session / restore last / stop saving |
| `Space g d / g h / g s` | Diffview / file history / Lazygit |
| `Space g b / g B` | DiffBandit repository changes / current file |
| `Space g c` | DiffBandit: everything this branch changed since the default branch (`origin/HEAD`, else `main`) |
| `Space J j / J s / J d / J e` | Jujutsu log / status / diff / describe |
| `Space u f / u i` | Toggle format-on-save / import changes on save |
| `Ctrl-Space` (insert mode) | Request completion (LSP, snippets, paths, SQL) |
| `Ctrl-n / Ctrl-p / Ctrl-y` (completion menu) | Next / previous / accept suggestion |
| `Down / Up / Enter` (completion menu) | Next / previous / accept selected suggestion |
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

Use `Space u c` to toggle completion for this Neovim session. Restarting Neovim
enables it again. A buffer explicitly disabled with `vim.b.completion = false`
stays disabled until you reset that buffer setting. `Ctrl-e` only dismisses the
current completion menu; `Ctrl-Space` requests suggestions while enabled.

`F7` toggles the project shell from Normal or Terminal mode; `Space T` is the
Normal-mode alternative. To navigate from an ordinary terminal, first press
`Ctrl-\ Ctrl-n`, then use `Ctrl-h/j/k/l`. Sidekick keeps its own local terminal
navigation shortcuts. Modified shortcuts such as `Ctrl-.` and `Ctrl-Shift-o/i`
depend on terminal keyboard encoding; `Space A a` and `Space j o/i` are the
portable alternatives.

Resize a Neovim split with `Ctrl-w <` / `Ctrl-w >` (width) and `Ctrl-w +` /
`Ctrl-w -` (height); put a count first for larger changes, such as `5 Ctrl-w >`.
`Ctrl-w =` makes the splits equal. These work for project terminal and Diffview
splits too, after leaving terminal input mode if necessary.

For Flash navigation, press `s` in Normal mode, type a few characters from
the target text, then press its displayed label to jump there. Press `S`
to select a labeled code structure, or Escape to cancel. These mappings
also work in Visual and operator-pending modes; `Space s g` opens project search.

mini.ai extends text objects: `cia` changes the argument under the cursor,
and `daa` deletes it with its separator. With mini.surround, `gsaiw"` wraps
the current word in double quotes, `gsd"` removes surrounding double quotes,
and `gsr"'` replaces them with single quotes. Surround uses `gs` so Flash's
`s` stays responsive; autopairs still inserts closing brackets while typing.

For project-wide replacement, press `Space s r`, fill in Search and Replace,
and review the matches. Press `Space r` in that buffer in Normal mode to apply
the replacement, or `Space c` to close it. Its window uses the detected project
root without changing the working directory of your existing file windows.
The Paths input can narrow the operation to particular files or directories.

Yanky keeps the last 100 copied/deleted entries in ShaDa between sessions.
Use `p`/`P` as usual, then `[y` or `]y` to cycle that paste before making
another edit. `Space y h` opens a history picker and pastes the chosen entry
after the cursor. `:YankyClearHistory` clears the saved history.

[Sidekick](https://github.com/folke/sidekick.nvim) runs OpenCode in an 80-column
right split. Press `Space A a` to open/hide it, or `Ctrl-.` from a file or
the terminal. If your terminal does not send Ctrl-., use `Ctrl-\ Ctrl-n`
to leave terminal mode, then `Space A a`. Hiding the window keeps the process
running. OpenCode now lives in a managed tmux session, so quitting Neovim
detaches its view while the agent keeps running. Reopen Neovim in that worktree
and press `Space A a` to reconnect.
Use `Ctrl-h` to return to your code while keeping OpenCode visible.

Sidekick uses the Git worktree root (or project root outside Git) and sets the
tab's working directory there. Agents are selected by worktree directory;
opening a second worktree starts a separate agent. `Space A f` adds the current file
path to its prompt; select text and press `Space A v` to add that selection.
These actions leave the prompt unsubmitted so you can add instructions and
press Enter yourself. Your existing OpenCode configuration and authentication
apply. Sidekick's Copilot next-edit suggestions are disabled; no Copilot setup
is required for this CLI workflow, and Blink's Tab/snippet mappings stay intact.

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
unselected until you choose one. Use Down/Up to select a suggestion and Enter
to accept it. When nothing is selected, Enter inserts a new line.
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

tmux uses `Ctrl-b v` to split right, `Ctrl-b -` to split down, and prefix plus
`h/j/k/l` to focus panes, matching Herdr. Prefix plus `q` detaches, `x` confirms
pane closure, `K` opens Sesh, and `r` reloads configuration. Default arrow-key
pane navigation also works.

Without the prefix, `Ctrl-h/j/k/l` moves between tmux panes and Neovim splits
as one grid (smart-splits.nvim), and `Alt-h/j/k/l` resizes. Those keys no longer
reach shells directly, so use `Ctrl-b Ctrl-l` to clear the screen and
`Ctrl-b Ctrl-k` / `Ctrl-b Ctrl-h` / `Ctrl-b Ctrl-j` for the other shell keys.
On macOS, set iTerm2's **Left Option key** to **Esc+** for the Alt bindings, and
enable **Report keys using CSI u** so `Ctrl-.` and `Ctrl-Shift-o/i` reach Neovim
through tmux (`extended-keys` is on).

Windows and panes number from 1, mouse support is on, scrollback holds 50000
lines, and copy mode uses vi keys: `Ctrl-b [`, `v` to start a selection, `y`
to copy it to the system clipboard.

The shell configuration is tracked at `zshrc`. `Ctrl-x Ctrl-e` edits the current
command line in Neovim, `Alt-s` opens the Sesh picker, a leading space keeps a
command out of the 50000-entry history, and typing a directory name changes to it. The installer links it to
`~/.zshrc`; rerun the installer after updating an existing checkout. Keep
editor selection, optional tool-manager hooks, and completions in
`~/.zshrc.local` as needed.

WezTerm reserves `Ctrl-Shift-t` for a new tab and leaves `Ctrl-t` available to
the shell's fzf file picker. VS Code's shell editing translations apply only
outside the terminal's alternate screen, and `Cmd-w` hides its panel while
leaving terminal processes running.

Use tmux for shell/editor projects and persistent agent workspaces. Herdr is
an optional alternative for its agent status tracking.
Do not run tmux inside Herdr because Herdr cannot detect agents behind tmux.

## Workspace tools

Install the CLI companions and activate their configuration:

```sh
sh ~/dotfiles/scripts/setup-workspace.sh
sh ~/dotfiles/install.sh
source ~/.zshrc
```

Setup installs missing tools with Homebrew or an existing Nix installation.
On other Linux installations, use the upstream instructions for
[zoxide](https://github.com/ajeetdsouza/zoxide#installation),
[sesh](https://github.com/joshmedeski/sesh#how-to-install), and
[Jujutsu](https://docs.jj-vcs.dev/latest/install-and-setup/), plus tmux and fzf,
then rerun setup.

Use `z dotfiles` to jump to a visited directory or `zi` for an interactive
directory picker. `sesh-pick` selects or creates a tmux project session;
inside tmux, `Ctrl-b K` opens the same picker in a popup. Sesh includes live
tmux sessions, the configured dotfiles project, and zoxide directory history.
Sesh manages tmux sessions; continue using Herdr's own workspace controls
when running Herdr. Neovim's Persistence shortcuts restore editor sessions.

[jj.nvim](https://github.com/NicolasGB/jj.nvim) exposes `:J log`, `:J status`,
`:J diff`, and `:J describe`. Use these inside a Jujutsu repository. To opt an
existing Git project into a colocated Jujutsu workflow, run `jj git init
--colocate` in that project yourself. Installation does not initialize any
repositories. The plugin uses Neovim's native diff backend.

[DiffBandit](https://github.com/CoreyKaylor/diffbandit.nvim) opens with
`Space g b`; `Space g B` limits it to the current file.
`Space g b` also works from Oil using the directory being browsed; `Space g B`
uses the file selected in Oil. Remote Oil directories are not supported.
Within the diff, use
`]f`/`[f` for files, `]c`/`[c` for hunks, and `q` to close. To review one
commit, run `:DiffBanditGitCommit HEAD`; for branches, use
`:DiffBanditGitCompare main HEAD`. Diffview and Lazygit remain available.
Connector rendering adapts to the terminal; iTerm2/tmux use Unicode cells.
Sidekick continues to run OpenCode with `Space A a` as documented above.

## Parallel agent workspaces

From any Git checkout or linked worktree, run:

```sh
agent-session agent/fix-auth
agent-session agent/add-tests
agent-session agent/experiment --base main
agent-session --list
```

Each task gets a Git worktree, a tmux workspace with `code` and `shell` windows,
and an OpenCode agent opened through Sidekick in the editor. New worktrees live
beside the primary checkout under `<repository>.worktrees/`. They start at the
current commit unless `--base` is supplied; uncommitted edits stay in the source
checkout. An existing branch can be used if it is not checked out in the primary
checkout. Re-running a task reuses its worktree and workspace instead of
resetting the branch or starting another editor.

From your current session, `Ctrl-b N` asks for a task branch and switches to its
workspace. Inside Neovim, `Space A n` does the same. Outside tmux, the shell
command attaches to the new workspace; the Neovim shortcut prints the attach
command instead. Install the helper with `sh ~/dotfiles/install.sh`, reload
Zsh and tmux, and restart Neovim after updating this configuration.

Use `Ctrl-b K` / `sesh-pick` to switch projects, `Ctrl-b c` for another window,
and `Ctrl-b L` to return to the previous workspace. Worktree directories are
added to zoxide, so they remain discoverable in Sesh even after a workspace is
closed. In the editor, `Space A a` toggles the worktree's agent, `Space A f` and
Visual `Space A v` add context without submitting it, and `Space g s` opens
Lazygit. Use `Space g b` for DiffBandit and your existing test/debug shortcuts
to review and validate the agent's work.

Sidekick stores its live agents in separate `opencode <hash>` tmux sessions.
Those are the agent backends; the repository/task-named sessions are your
workspaces. Closing Neovim or detaching tmux leaves agents running; stopping
the agent, killing its backend session, stopping the tmux server, or rebooting
ends the process. This does not provide Herdr-style status tracking or automatic
process recovery after a reboot.

When a task is finished, review/commit/merge it, exit its OpenCode agent, and
close its task workspace. Use `git worktree list` to find the exact path, then
`git worktree remove /path/to/task-worktree` and optionally `git branch -d
agent/fix-auth`. Git's normal checks protect uncommitted work and unmerged
branches; no automatic cleanup or force removal is configured.

## Updates

```sh
herdr update                    # direct Herdr install only
brew upgrade                    # Homebrew-managed tools
nix profile upgrade '.*'        # Nix profile tools
opencode upgrade
```

Restart OpenCode after changing files under `.config/opencode`. Reload Herdr
with `herdr server reload-config` and tmux with `Ctrl-b r`.
