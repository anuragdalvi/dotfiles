#!/bin/sh
set -eu
for tool in sesh fzf tmux zoxide; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Run scripts/setup-workspace.sh.\n' "$tool" >&2
    exit 1
  fi
done
# Treat cancelling the picker as a successful no-op; quote paths with spaces.
selection=$(sesh list | fzf --reverse --border --prompt='Session> ') || exit 0
[ -n "$selection" ] || exit 0
exec sesh connect "$selection"
