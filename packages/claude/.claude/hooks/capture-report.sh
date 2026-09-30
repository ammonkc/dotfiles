#!/bin/bash
# PostToolUse(Write) hook: copy ~/.claude/reports/*.md to Obsidian Projects/Engineering/Research
# and log it in the daily journal. Report frontmatter supplies title, summary, tags.

set -o pipefail

DEBUG_LOG="/tmp/capture-report-debug.log"
INPUT=$(cat)

[ "$(echo "$INPUT" | jq -r '.tool_name // empty')" = "Write" ] || exit 0
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FILE_PATH" in
  "$HOME"/.claude/reports/*.md) ;;
  *) exit 0 ;;
esac
[ -f "$FILE_PATH" ] || exit 0

if [ -z "$CAPTURE_REPORT_FG" ] && [ -z "$CAPTURE_REPORT_BG" ]; then
  printf '%s' "$INPUT" | CAPTURE_REPORT_BG=1 nohup "$0" >/dev/null 2>&1 &
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

_OBSIDIAN_JSON="$HOME/Library/Application Support/obsidian/obsidian.json"
VAULT_ROOT=$(jq -r '(.vaults | to_entries[] | select(.value.open == true) | .value.path) // (.vaults | to_entries[0].value.path) // ""' "$_OBSIDIAN_JSON" 2>/dev/null | head -1)
if [ -z "$VAULT_ROOT" ] || [[ "$VAULT_ROOT" != /* ]] || [ ! -d "$VAULT_ROOT" ]; then
  echo "$(date) VAULT_ROOT invalid: ${VAULT_ROOT:-<empty>}" >> "$DEBUG_LOG"
  exit 0
fi

python3 - "$FILE_PATH" "$VAULT_ROOT" "$SESSION_ID" << 'PYEOF' >> "$DEBUG_LOG" 2>&1
import os, re, sys
from datetime import datetime

src, vault, session = sys.argv[1:4]
text = open(src).read()

fm, body = {}, text
m = re.match(r'^---\n(.*?)\n---\n(.*)', text, re.DOTALL)
if m:
    for line in m.group(1).splitlines():
        k, _, v = line.partition(':')
        fm[k.strip()] = v.strip()
    body = m.group(2)

title = fm.get('title') or next((re.sub(r'^#+\s*', '', l).strip() for l in body.splitlines() if l.strip()), 'Unnamed Report')
summary = fm.get('summary') or 'Research report captured from Claude Code.'
tags = [t.strip() for t in fm.get('tags', '').split(',') if t.strip()] or ['research']

now = datetime.now()
date_prefix = now.strftime('%m-%d-%Y')
slug = re.sub(r'-+', '-', re.sub(r'[^a-z0-9\s-]', '', title.lower().replace('&', ' and ')).replace(' ', '-')).strip('-')[:80] or 'unnamed-report'
note_rel = f'Projects/Engineering/Research/{date_prefix}-{slug}'
journal_rel = f'Journal/{now.year}/{now.strftime("%m-%B")}/{date_prefix}'

tag_lines = ''.join(f'  - {t}\n' for t in ['research', 'claude-session'] + [t for t in tags if t != 'research'])
note = f'''---
created: {now.strftime('%m/%d/%Y')}
tags:
{tag_lines}source: Claude Code (Research)
session: {session}
---

# {title}

## Logged In
[[{journal_rel}]]

{body.lstrip()}'''

dest = os.path.join(vault, note_rel + '.md')
os.makedirs(os.path.dirname(dest), exist_ok=True)
open(dest, 'w').write(note)

jf = os.path.join(vault, journal_rel + '.md')
os.makedirs(os.path.dirname(jf), exist_ok=True)
existing = open(jf).read() if os.path.exists(jf) else ''
if f'[[{note_rel}|' not in existing:
    with open(jf, 'a') as f:
        f.write(f'\n- [[{note_rel}|{title}]] (research)\n  - {summary}\n')
print(f'{now}: wrote {dest}')
PYEOF
exit 0
