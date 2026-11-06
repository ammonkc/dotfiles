#!/usr/bin/env python3
"""Parse tracked configuration with its format parser, reporting every failure."""
import json
from pathlib import Path
import subprocess
import sys
import tomllib

import json5
import yaml

root = Path(__file__).resolve().parent.parent
names = subprocess.check_output(
    ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root
).decode().split('\0')
count = 0
failed = 0
for name in sorted(set(names)):
    path = root / name
    if not path.is_file() or path.is_symlink():
        continue
    if not (name.startswith(('packages/', 'taskfiles/', '.github/')) or name == 'taskfile.dist.yml'):
        continue
    if path.suffix not in ('.json', '.jsonc', '.toml', '.yaml', '.yml'):
        continue
    count += 1
    try:
        text = path.read_text()
        if path.suffix == '.toml':
            tomllib.loads(text)
        elif path.suffix in ('.yaml', '.yml'):
            yaml.safe_load(text)
        elif path.suffix == '.jsonc' or name.startswith(('packages/zed/', 'packages/cursor/', 'packages/vscode/')) or path.name == 'tsconfig.json':
            json5.loads(text, allow_duplicate_keys=False)
        else:
            json.loads(text)
    except (ValueError, yaml.YAMLError) as error:
        print(f'FAIL {name}: {error}', file=sys.stderr)
        failed += 1
print(f'Configuration files parsed: {count}; failures: {failed}')
sys.exit(bool(failed))
