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


def merge_opencode(existing, fragment, home, plugin_dir=None):
    result = deepcopy(existing)
    result.setdefault("worktree", {}).update(fragment["worktree"])
    old_path = str(home / ".config/opencode/plugins/worktrunk")
    legacy = {"./plugins/worktrunk", "~/.config/opencode/plugins/worktrunk", old_path, "file://" + old_path}
    managed = deepcopy(fragment["plugins"][0])
    default_package = managed["package"]
    if default_package.startswith("~/"):
        default_package = str(home / default_package[2:])
    legacy.add(str(Path(default_package).resolve()))
    package = str(plugin_dir) if plugin_dir else managed["package"]
    if package.startswith("~/"):
        package = str(home / package[2:])
    managed["package"] = str(Path(package).resolve())
    kept = []
    options = {}
    for entry in result.get("plugins", []):
        reference = entry if isinstance(entry, str) else entry.get("package")
        normalized = reference
        if isinstance(reference, str) and reference.startswith(("/", "file://", "~/")):
            path = reference.removeprefix("file://")
            if path.startswith("~/"):
                path = str(home / path[2:])
            normalized = str(Path(path).resolve())
        external_copy = False
        if isinstance(normalized, str) and normalized.startswith("/"):
            manifest_path = Path(normalized) / "package.json"
            try:
                external_copy = json.loads(manifest_path.read_text()).get("name") == "@ammonkc/opencode-worktrunk"
            except (OSError, ValueError):
                pass
        if reference in legacy or normalized in {old_path, managed["package"]} or external_copy:
            if isinstance(entry, dict):
                options.update(entry.get("options", {}))
        else:
            kept.append(entry)
    options.update(managed.get("options", {}))
    if options:
        managed["options"] = options
    result["plugins"] = [*kept, managed]
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
    parser.add_argument("--opencode-plugin-dir", type=Path,
                        help="Override the external plugin checkout for testing")
    args = parser.parse_args()
    args.home = args.home.resolve()
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
        settings = json.loads(fragment.read_text())
        if merge is merge_opencode:
            merged = merge(existing, settings, args.home, args.opencode_plugin_dir)
            package_dir = Path(merged["plugins"][-1]["package"])
            for filename in ("index.mjs", "package.json", "package-lock.json"):
                if not (package_dir / filename).is_file():
                    raise ValueError(f"External OpenCode plugin is not available at {package_dir}; "
                                     "make the reviewed claude-fiyah package available before activating")
            manifest = json.loads((package_dir / "package.json").read_text())
            if manifest.get("name") != "@ammonkc/opencode-worktrunk":
                raise ValueError("The external package is not @ammonkc/opencode-worktrunk")
        else:
            merged = merge(existing, settings)
        pending.append((target, merged))
    for target, data in pending:
        write_config(target, data)
        print(f"Worktree settings configured: {target}")


if __name__ == "__main__":
    main()
