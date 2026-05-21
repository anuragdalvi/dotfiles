export PATH=$HOME/bin:$PATH
export PATH="/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/usr/local:$PATH"

#Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

#Python
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
alias python=python3

#Kubernetes
alias k=kubectl

#ssh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github.com
ssh-add ~/.ssh/adalvi

#AWSProfile
#export AWS_PROFILE=base
export AWS_PAGER=""

#Git
parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}
COLOR_DEF='%f'
COLOR_DIR='%F{84}'
COLOR_GIT='%F{84}'
NEWLINE=$'\n'
setopt PROMPT_SUBST
export PROMPT='${COLOR_DIR}%~ ${COLOR_GIT}$(parse_git_branch)${COLOR_DEF}${NEWLINE}% $ '

#Terminal

#Plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

## set up fzf key bindings and fuzzy completion.
source <(fzf --zsh)

#History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=5000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

#CaseInsensitiveCompletion
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'


#EmacsKeyBinding
bindkey -e

#Source
#https://thevaluable.dev/zsh-install-configure-mouseless/

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# ── Terminal text-editing parity (iTerm Natural Text Editing ↔ VSCode) ──
# Complements the emacs defaults (bindkey -e above) so ⌥/⌘ + arrows/backspace
# behave identically in iTerm and the VSCode integrated terminal.
bindkey '^[[1;3D' backward-word        # ⌥←  (CSI form, e.g. before iTerm preset)
bindkey '^[[1;3C' forward-word         # ⌥→
bindkey '^[[1;9D' backward-word        # ⌥←  (alternate CSI form)
bindkey '^[[1;9C' forward-word         # ⌥→
bindkey '^[b'     backward-word        # ⌥←  (Meta-b, sent by Natural Text Editing)
bindkey '^[f'     forward-word         # ⌥→  (Meta-f)
bindkey '^[^?'    backward-kill-word   # ⌥⌫  delete previous word
bindkey '^U'      backward-kill-line   # ⌘⌫  delete to start of line (macOS-like; default is kill-whole-line)
