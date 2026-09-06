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
export EDITOR=nvim
export VISUAL=nvim
export AWS_PAGER=""

alias python=python3
alias k=kubectl

# Keep host-specific SSH keys and agents out of shared shell startup. macOS
# Keychain and Ubuntu's desktop session normally provide SSH_AUTH_SOCK.

autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=5000
setopt appendhistory sharehistory hist_ignore_all_dups hist_save_no_dups

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

if [[ -r "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -o interactive && -t 0 ]]; then
  if (( $+commands[fzf] )) && fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  elif [[ -r "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
  fi
fi

[[ -r "$HOME/.config/envman/load.sh" ]] && source "$HOME/.config/envman/load.sh"
(( $+commands[kubectl] )) && source <(kubectl completion zsh)
(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[pyenv] )) && eval "$(pyenv init -)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Static completion avoids launching a sandboxed OpenCode during shell startup.
if [[ -r "$XDG_CONFIG_HOME/zsh/completions/_opencode" ]]; then
  source "$XDG_CONFIG_HOME/zsh/completions/_opencode"
fi
