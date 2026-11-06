#!/usr/bin/env python3
"""Validate each repository shell file, without loading home configuration."""
import argparse
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--lint', action='store_true', help='also run ShellCheck')
args = parser.parse_args()
# Include untracked new files locally, but never ignored dependencies or builds.
names = subprocess.check_output(
    ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root
).decode().split('\0')
failed = 0
counts = {'bash': 0, 'sh': 0, 'zsh': 0}
for name in sorted(set(names)):
    path = root / name
    if not path.is_file() or path.is_symlink():
        continue
    if not (name.startswith(('scripts/', 'bin/', 'tests/', 'packages/bin/', 'packages/zsh/'))
            or '/script-commands/' in name):
        continue
    first = path.read_text(errors='replace').split('\n', 1)[0]
    shell = None
    if name.startswith('packages/zsh/') and (path.suffix == '.zsh'
            or path.name in ('.zshrc', '.zshenv', '.zprofile') or '/functions/' in name):
        shell = 'zsh'
    elif first.startswith('#!'):
        for candidate in ('bash', 'zsh', 'sh'):
            if first.split()[-1].split('/')[-1] == candidate:
                shell = candidate
                break
    if shell is None:
        continue
    counts[shell] += 1
    commands = [[f'/bin/{shell}' if shell != 'zsh' else 'zsh', '-n', name]]
    if args.lint and shell != 'zsh':
        commands.append(['shellcheck', '--severity=warning', '--external-sources', name])
    for command in commands:
        result = subprocess.run(command, cwd=root, capture_output=True, text=True)
        if result.returncode:
            print(f'FAIL {name} ({command[0]})\n{result.stdout}{result.stderr}', file=sys.stderr)
            failed += 1
print(f'Shell files checked: {counts}; failed checks: {failed}')
sys.exit(bool(failed))
