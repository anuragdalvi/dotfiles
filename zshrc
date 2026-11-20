# Shared interactive Zsh configuration for macOS and Ubuntu.

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  /usr/local/sbin
  $path
)

export GOPATH="$HOME/go"
export GOTOOLCHAIN="auto"
export AWS_PAGER=""
# Default editor; ~/.zshrc.local may override it.
export EDITOR=${EDITOR:-nvim} VISUAL=${VISUAL:-nvim}

# Homebrew completions live outside Zsh's default system completion paths.
if (( $+commands[brew] )); then
  _dotfiles_brew_prefix=$(brew --prefix)
  fpath=("$_dotfiles_brew_prefix/share/zsh/site-functions" $fpath)
fi

alias python=python3
alias k=kubectl
alias lg=lazygit

# Directory history and interactive project/session switching.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
sesh-pick() {
  sh "$XDG_CONFIG_HOME/sesh/picker.sh"
}
agent-session() {
  python3 "$XDG_CONFIG_HOME/tmux/agent-session.py" "$@"
}

# Keep host-specific SSH keys and agents out of shared shell startup. macOS
# Keychain and Ubuntu's desktop session normally provide SSH_AUTH_SOCK.

autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

HISTSIZE=50000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=50000
# A leading space keeps a command out of history; a bare directory name cds.
setopt appendhistory sharehistory hist_ignore_all_dups hist_save_no_dups hist_ignore_space autocd

# Show the abbreviated working directory and Git branch above a plain prompt.
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' [%b]'
set_workspace_prompt() {
  vcs_info
  PROMPT="%~${vcs_info_msg_0_}"$'\n$ '
}
add-zsh-hook precmd set_workspace_prompt
set_workspace_prompt

# ZLE Emacs mode gives the shell and OpenCode the same text-editing model.
bindkey -e
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;9D' backward-word
bindkey '^[[1;9C' forward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[^?' backward-kill-word
bindkey '^U' backward-kill-line

# Ctrl-x Ctrl-e edits the current command line in $EDITOR (Neovim).
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Alt-s opens the Sesh project picker from any prompt.
_dotfiles_sesh_widget() {
  zle -I
  sesh-pick <"$TTY"  # tmux rejects the /dev/tty alias
  zle reset-prompt
}
zle -N _dotfiles_sesh_widget
bindkey '^[s' _dotfiles_sesh_widget

for _dotfiles_suggestions in \
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "${_dotfiles_brew_prefix:-/nonexistent}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -r "$_dotfiles_suggestions" ]]; then
    source "$_dotfiles_suggestions"
    break
  fi
done

if [[ -o interactive && -t 0 ]]; then
  if (( $+commands[fzf] )) && fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  elif [[ -r "${_dotfiles_brew_prefix:-/nonexistent}/opt/fzf/shell/key-bindings.zsh" ]]; then
    source "$_dotfiles_brew_prefix/opt/fzf/shell/key-bindings.zsh"
  elif [[ -r "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
  fi
fi

unset _dotfiles_brew_prefix _dotfiles_suggestions

[[ -r "$XDG_CONFIG_HOME/envman/load.sh" ]] && source "$XDG_CONFIG_HOME/envman/load.sh"
(( $+commands[kubectl] )) && source <(kubectl completion zsh)
(( $+commands[pyenv] )) && eval "$(pyenv init -)"

# Load machine-specific settings that should not be committed to dotfiles.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
