#!/usr/bin/env python3
"""Create/reopen a Git worktree with a tmux editor and persistent Sidekick agent."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def run(args, cwd=None, check=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if check and result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or 'Command failed: ' + args[0])
    return result


def git(directory, *args, check=True):
    return run(['git', '-C', str(directory), *args], check=check)


def worktrees(directory):
    records, entry = [], {}
    for field in git(directory, 'worktree', 'list', '--porcelain', '-z').stdout.split('\0'):
        if not field:
            if entry:
                records.append(entry)
                entry = {}
        else:
            key, _, value = field.partition(' ')
            entry[key] = value
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('branch', nargs='?', help='task branch (new or existing)')
    parser.add_argument('--base', help='start a new branch at this ref; default is current HEAD')
    parser.add_argument('--from', dest='directory', default=os.getcwd(), help='repository or worktree to start from')
    parser.add_argument('--prompt', action='store_true', help='ask for the branch interactively')
    parser.add_argument('--no-switch', action='store_true', help='print workspace JSON without attaching/switching')
    parser.add_argument('--list', action='store_true', help='list this repository\'s worktrees')
    args = parser.parse_args()
    directory = Path(args.directory).expanduser().resolve()
    git(directory, 'rev-parse', '--show-toplevel')  # Fail before any mutation outside a Git repo.
    if args.list:
        for entry in worktrees(directory):
            print(entry.get('branch', 'detached').removeprefix('refs/heads/'), entry['worktree'], sep='\t')
        return
    for tool in ('tmux', 'nvim', 'opencode'):
        if not shutil.which(tool):
            raise RuntimeError('Missing executable: ' + tool)
    branch = args.branch
    if args.prompt and not branch:
        branch = input('New agent worktree branch (e.g. agent/fix-auth): ').strip()
        if not branch:
            return
    if not branch:
        parser.error('provide a task branch, --prompt, or --list')
    valid = git(directory, 'check-ref-format', '--branch', branch, check=False)
    if valid.returncode or valid.stdout.strip() != branch:
        raise RuntimeError('Invalid branch name: ' + branch)
    # The primary worktree is the first record, including when invoked from a linked worktree.
    entries = worktrees(directory)
    primary = Path(entries[0]['worktree'])
    if 'bare' in entries[0]:
        raise RuntimeError('Start from a non-bare repository or worktree')
    repo_name = primary.name
    slug = re.sub(r'[^A-Za-z0-9_-]+', '-', branch).strip('-')[:48]
    suffix = hashlib.sha256(branch.encode()).hexdigest()[:8]
    target = primary.parent / (repo_name + '.worktrees') / (slug + '-' + suffix)
    existing = next((entry for entry in entries if entry.get('branch') == 'refs/heads/' + branch), None)
    if existing:
        if args.base:
            raise RuntimeError('--base only applies to a new branch')
        target = Path(existing['worktree']).resolve()
        if target == primary.resolve():
            raise RuntimeError('That branch is checked out in the primary checkout; choose a separate task branch')
        if not target.is_dir():
            raise RuntimeError('The branch has a missing worktree; inspect git worktree list before retrying')
    else:
        if target.exists():
            raise RuntimeError('Worktree destination already exists: ' + str(target))
        exists = git(directory, 'show-ref', '--verify', '--quiet', 'refs/heads/' + branch, check=False).returncode == 0
        if exists and args.base:
            raise RuntimeError('--base only applies to a new branch')
        base_commit = None
        if not exists:
            base_commit = git(directory, 'rev-parse', '--verify', '--end-of-options', (args.base or 'HEAD') + '^{commit}').stdout.strip()
        target.parent.mkdir(parents=True, exist_ok=True)
        command = ['worktree', 'add']
        if not exists:
            command += ['-b', branch]
        command += [str(target), branch if exists else base_commit]
        git(directory, *command)
    identity = hashlib.sha256(str(target).encode()).hexdigest()[:8]
    repo_slug = re.sub(r'[^A-Za-z0-9_-]+', '-', repo_name)[:28]
    name = f'{repo_slug}-{slug[:28]}-{identity}'
    found = run(['tmux', 'has-session', '-t', name], check=False).returncode == 0
    if found:
        owner = run(['tmux', 'show-options', '-qv', '-t', name, '@dotfiles_worktree']).stdout.strip()
        if owner != str(target):
            raise RuntimeError('An unrelated tmux session already uses the name: ' + name)
    else:
        run(['tmux', 'new-session', '-d', '-s', name, '-n', 'code', '-c', str(target),
             shutil.which('nvim'), '-c', "lua require('dotfiles.ai').open()", '.'])
        run(['tmux', 'set-option', '-t', name, '@dotfiles_worktree', str(target)])
        run(['tmux', 'new-window', '-d', '-t', name + ':', '-n', 'shell', '-c', str(target)])
    if shutil.which('zoxide'):
        run(['zoxide', 'add', str(target)], check=False)
    workspace = {'session': name, 'worktree': str(target), 'branch': branch}
    if args.no_switch:
        print(json.dumps(workspace))
    elif os.environ.get('TMUX'):
        run(['tmux', 'switch-client', '-t', name])
    else:
        os.execvp('tmux', ['tmux', 'attach-session', '-t', name])


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, EOFError, KeyboardInterrupt) as error:
        print(str(error) or 'Cancelled', file=sys.stderr)
        sys.exit(1)
