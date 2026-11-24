#!/bin/bash
# Every `task:` reference must name a real task, resolved from its own namespace,
# and read-only tasks must render with --dry. Catches missing leading colons,
# trailing shell fragments such as `|| true`, and Go templates eaten by Task.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
python3 -I - "$root" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])

def parse(path):
    """Return (includes, tasks, refs) for a taskfile using its top-level layout."""
    includes, tasks, refs = {}, set(), []
    section, current = None, None
    for lineno, line in enumerate(path.read_text().splitlines(), 1):
        if re.match(r"^\S", line):
            section = line.split(":")[0]
            continue
        if section == "includes":
            m = re.match(r"^  (\w+):\s*$", line)
            if m:
                current = includes.setdefault(m.group(1), {"aliases": []})
            m = re.match(r"^    taskfile:\s*(\S+)", line)
            if m and current is not None:
                current["file"] = (path.parent / m.group(1)).resolve()
            m = re.match(r"^    aliases:\s*\[(.*)\]", line)
            if m and current is not None:
                current["aliases"] = [a.strip() for a in m.group(1).split(",") if a.strip()]
        elif section == "tasks":
            m = re.match(r"^  ([\w:.-]+):\s*$", line)
            if m:
                tasks.add(m.group(1))
        m = re.match(r"^\s*(?:- )?task:\s*(.*?)\s*(?:#.*)?$", line)
        if m:
            refs.append((lineno, m.group(1).strip("'\"")))
    return includes, tasks, refs

# Every instance of a taskfile is (namespace, file). Namespaces nest through includes,
# and an alias is an alternative spelling of one namespace segment.
instances, names = [], set()
def walk(ns, path):
    includes, tasks, refs = parse(path)
    instances.append((ns, path, refs))
    for t in tasks:
        names.add(f"{ns}:{t}" if ns else t)
    for key, inc in includes.items():
        if "file" not in inc:
            continue
        for seg in [key, *inc["aliases"]]:
            walk(f"{ns}:{seg}" if ns else seg, inc["file"])
walk("", (root / "taskfile.dist.yml").resolve())

valid = re.compile(r"^:?[\w.-]+(:[\w.-]+)*$")
errors = []
for ns, path, refs in instances:
    rel = path.relative_to(root)
    for lineno, ref in refs:
        if "{{" in ref:
            continue
        if not valid.match(ref):
            errors.append(f"{rel}:{lineno}: malformed task reference {ref!r}")
            continue
        full = ref[1:] if ref.startswith(":") else (f"{ns}:{ref}" if ns else ref)
        if full not in names:
            errors.append(f"{rel}:{lineno}: task {ref!r} does not resolve in namespace {ns or '(root)'!r}")
if errors:
    print("\n".join(sorted(set(errors))), file=sys.stderr)
    sys.exit(1)
PY

# Read-only tasks must at least render. Template or namespace errors fail here.
for name in clean:all clean:backups clean:packages git:sync docker:ps docker:images develop:list; do
  task --dry "$name" >/dev/null 2>"${TMPDIR:-/tmp}/task-dry.$$.err" || {
    echo "task --dry $name failed:" >&2
    cat "${TMPDIR:-/tmp}/task-dry.$$.err" >&2
    rm -f "${TMPDIR:-/tmp}/task-dry.$$.err"
    exit 1
  }
done
rm -f "${TMPDIR:-/tmp}/task-dry.$$.err"
printf 'Task references and dry runs passed.\n'
