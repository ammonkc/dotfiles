#!/usr/bin/env python3
"""Merge non-secret worktree fragments into existing user settings, with backups."""
import argparse
from copy import deepcopy
import json
import os
from pathlib import Path
import shutil
import tempfile


def merge_claude(existing, fragment):
    result = deepcopy(existing)
    hooks = result.setdefault("hooks", {})
    for event, handlers in fragment["hooks"].items():
        old = hooks.get(event, [])
        if old and old != handlers:
            raise ValueError(f"Existing {event} hooks conflict; review them before installing the shared workflow")
        hooks[event] = handlers
    return result


def merge_opencode(existing, fragment):
    result = deepcopy(existing)
    result.setdefault("worktree", {}).update(fragment["worktree"])
    plugins = result.setdefault("plugins", [])
    for plugin in fragment["plugins"]:
        if plugin not in plugins:
            plugins.append(plugin)
    return result


def write_config(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink():
        raise ValueError(f"Refusing to overwrite symlinked settings: {path}")
    if path.exists():
        current = json.loads(path.read_text())
        if current == data:
            return
        fd, backup = tempfile.mkstemp(prefix=path.name + ".backup.", dir=path.parent)
        os.close(fd)
        shutil.copyfile(path, backup)
    fd, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(data, stream, indent=2)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home())
    args = parser.parse_args()
    targets = [
        (args.home / ".claude/settings.json", args.home / ".claude/worktree-settings.json", merge_claude),
        (args.home / ".config/opencode/opencode.json", args.home / ".config/opencode/worktree-settings.json", merge_opencode),
    ]
    pending = []
    # Validate both merges before changing either settings file.
    for target, fragment, merge in targets:
        if target.is_symlink():
            raise ValueError(f"Refusing to overwrite symlinked settings: {target}")
        if target.with_suffix(".jsonc").exists():
            raise ValueError(f"JSONC settings also exist for {target.parent}; consolidate them before installing")
        existing = json.loads(target.read_text()) if target.exists() else {}
        pending.append((target, merge(existing, json.loads(fragment.read_text()))))
    for target, data in pending:
        write_config(target, data)
        print(f"Worktree settings configured: {target}")


if __name__ == "__main__":
    main()
