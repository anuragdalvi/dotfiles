"""Run with python3 tests/workspaces.py; uses dummy CLIs and an isolated tmux server."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import uuid


def main():
    repo = Path(__file__).resolve().parents[1]
    helper = repo / '.config/tmux/agent-session.py'
    real_tmux = shutil.which('tmux')
    assert real_tmux, 'Install tmux before running workspace checks'
    server = 'dotfiles-workspace-test-' + uuid.uuid4().hex[:8]
    base = [real_tmux, '-L', server]
    with tempfile.TemporaryDirectory(prefix='dotfiles-workspace-') as temporary:
        folder = Path(temporary).resolve()
        checkout = folder / 'repo with spaces'
        binaries = folder / 'bin'
        binaries.mkdir()
        for name, text in {
            'tmux': '#!/bin/sh\nexec ' + real_tmux + ' -L ' + server + ' "$@"\n',
            'nvim': '#!/bin/sh\nexec cat\n',
            'opencode': '#!/bin/sh\nexec cat\n',
            'zoxide': '#!/bin/sh\nprintf "%s\\n" "$2" >> "$DOTFILES_ZOXIDE_LOG"\n',
        }.items():
            (binaries / name).write_text(text)
            (binaries / name).chmod(0o755)
        env = dict(os.environ, PATH=str(binaries) + ':' + os.environ['PATH'],
                   DOTFILES_ZOXIDE_LOG=str(folder / 'zoxide.log'))

        def git(*args, cwd=checkout):
            result = subprocess.run(['git', '-C', str(cwd), *args], check=True, capture_output=True, text=True)
            return result.stdout.strip()

        def invoke(branch, *options, cwd=checkout, success=True):
            result = subprocess.run([sys.executable, str(helper), '--no-switch', branch, *options],
                                    cwd=cwd, env=env, text=True, capture_output=True)
            assert (result.returncode == 0) == success, result.stderr
            return json.loads(result.stdout) if success else result.stderr

        try:
            checkout.mkdir()
            git('init', '-q', '-b', 'main')
            (checkout / 'example.txt').write_text('committed\n')
            git('add', 'example.txt')
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'fixture')
            original_head = git('rev-parse', 'HEAD')
            (checkout / 'example.txt').write_text('uncommitted\n')
            first = invoke('agent/fix-auth')
            assert Path(first['worktree']).parent == folder / 'repo with spaces.worktrees'
            assert (Path(first['worktree']) / 'example.txt').read_text() == 'committed\n'
            assert (checkout / 'example.txt').read_text() == 'uncommitted\n'
            assert git('rev-parse', 'HEAD') == original_head
            assert invoke('agent/fix-auth') == first, 'Retry did not reuse the workspace'
            windows = subprocess.run(base + ['list-windows', '-t', first['session'], '-F', '#{window_name}'],
                                     check=True, capture_output=True, text=True).stdout.splitlines()
            assert windows == ['code', 'shell'], windows
            linked = Path(first['worktree'])
            (linked / 'example.txt').write_text('task commit\n')
            git('add', 'example.txt', cwd=linked)
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'task', cwd=linked)
            task_head = git('rev-parse', 'HEAD', cwd=linked)
            second = invoke('agent/add-tests', cwd=linked)
            assert git('rev-parse', 'HEAD', cwd=Path(second['worktree'])) == task_head
            assert git('rev-parse', 'HEAD') == original_head
            based = invoke('agent/from-main', '--base', 'main', cwd=linked)
            assert git('rev-parse', 'HEAD', cwd=Path(based['worktree'])) == original_head
            git('branch', 'existing-task')
            existing = invoke('existing-task')
            assert git('branch', '--show-current', cwd=Path(existing['worktree'])) == 'existing-task'
            assert 'primary checkout' in invoke('main', success=False)
            assert 'Invalid branch' in invoke('invalid branch', success=False)
            assert '--base only applies' in invoke('existing-task', '--base', 'main', success=False)
            listed = subprocess.run([sys.executable, str(helper), '--list'], cwd=linked,
                                    text=True, capture_output=True, check=True).stdout
            assert 'agent/add-tests' in listed and 'agent/fix-auth' in listed
            assert first['worktree'] in (folder / 'zoxide.log').read_text()
            print('Workspace checks passed: isolation, dirty source preservation, reuse, linked bases, existing branches, guards, listing')
        finally:
            subprocess.run(base + ['kill-server'], capture_output=True)


if __name__ == '__main__':
    main()
