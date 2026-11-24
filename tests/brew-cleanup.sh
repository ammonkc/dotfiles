#!/bin/bash
# Homebrew keeps every downloaded installer in its cache, which fills small disks during a
# bundle. The install and retry tasks must clear it after each bundle without failing the install.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
python3 -I - "$root/taskfiles/brew.yml" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
CLEAN = "brew cleanup --prune=all"

def body(name):
    m = re.search(rf"^  {re.escape(name)}:\n(.*?)(?=^  \S|\Z)", text, re.M | re.S)
    assert m, f"task {name} not found"
    return m.group(1)

def lines(task):
    return body(task).splitlines()

errors = []
for task in ("retry", "install:tools"):
    for line in lines(task):
        if CLEAN in line and "||" not in line:
            errors.append(f"{task}: cleanup can abort the install: {line.strip()}")

# retry: one cleanup after its bundle.
retry = body("retry")
if CLEAN not in retry or retry.index(CLEAN) < retry.index("brew bundle"):
    errors.append("retry must run brew cleanup after brew bundle")

# install:tools: cleanup after the core bundle and again after the full bundle.
tools = body("install:tools")
core = tools.index('Brewfile.core"')
full = tools.index('Brewfile"; then')
cleanups = [m.start() for m in re.finditer(re.escape(CLEAN), tools)]
if not any(core < c < tools.index("case ") for c in cleanups):
    errors.append("install:tools must run brew cleanup between the core and full bundles")
if not any(c > tools.index("esac") for c in cleanups):
    errors.append("install:tools must run brew cleanup after the full bundle")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
PY
printf 'Brew cleanup checks passed.\n'
