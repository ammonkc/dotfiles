#!/usr/bin/env bash
# ============================================================
# capture-superpowers.sh — Claude Code Hook for Write tool
# Captures superpowers plan and spec files to Obsidian vault
# ============================================================

set -euo pipefail

DEBUG_LOG="/tmp/capture-superpowers-debug.log"

INPUT=$(cat)

{
  echo "=== $(date) ==="
  echo "$INPUT" | head -c 500
  echo ""
  echo "---"
} >> "$DEBUG_LOG"

# Only handle Write tool events
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Path detection: only capture superpowers plans/specs ---
# Match against the relative portion containing docs/superpowers/
NOTE_TYPE=""
if [[ "$FILE_PATH" == */docs/superpowers/plans/*.md ]]; then
  NOTE_TYPE="plan"
elif [[ "$FILE_PATH" == */docs/superpowers/specs/*.md ]]; then
  NOTE_TYPE="spec"
else
  exit 0
fi

{
  echo "Matched NOTE_TYPE=$NOTE_TYPE for FILE_PATH=$FILE_PATH"
} >> "$DEBUG_LOG"

# --- Read content from tool_input ---
FILE_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

if [ -z "$FILE_CONTENT" ] || [ ${#FILE_CONTENT} -lt 20 ]; then
  echo "No valid content in Write event for $FILE_PATH" >> "$DEBUG_LOG"
  exit 0
fi

# --- Parse filename: YYYY-MM-DD-slug.md → vault date parts ---
FILENAME=$(basename "$FILE_PATH" .md)

EXTRACTED=$(python3 - "$FILENAME" << 'PYEOF'
import json, re, sys
from datetime import datetime

fn = sys.argv[1]
m = re.match(r'^(\d{4})-(\d{2})-(\d{2})-(.+)$', fn)
if not m:
    sys.exit(1)

yyyy, mm, dd, slug = m.groups()
date_created = f"{mm}/{dd}/{yyyy}"
date_prefix = f"{mm}-{dd}-{yyyy}"
month_name = datetime.strptime(mm, '%m').strftime('%B')
month_dir = f"{mm}-{month_name}"

print(json.dumps({
    "date_created": date_created,
    "date_prefix": date_prefix,
    "year": yyyy,
    "month_dir": month_dir,
    "slug": slug,
    "vault_filename": f"{date_prefix}-{slug}",
}))
PYEOF
) || {
  echo "Failed to parse filename: $FILENAME" >> "$DEBUG_LOG"
  exit 0
}

DATE_CREATED=$(echo "$EXTRACTED" | jq -r '.date_created')
DATE_PREFIX=$(echo "$EXTRACTED" | jq -r '.date_prefix')
YEAR=$(echo "$EXTRACTED" | jq -r '.year')
MONTH_DIR=$(echo "$EXTRACTED" | jq -r '.month_dir')
VAULT_FILENAME=$(echo "$EXTRACTED" | jq -r '.vault_filename')

# --- Extract title from first heading ---
NOTE_TITLE=$(python3 - "$FILE_CONTENT" << 'PYEOF'
import re, sys

content = sys.argv[1]
for raw_line in content.splitlines():
    line = raw_line.strip()
    if not line:
        continue
    m = re.match(r'^#+\s+(.+)', line)
    if m:
        title = m.group(1)
        title = re.sub(r'[`*_]', '', title)
        title = re.sub(r'\s+', ' ', title).strip()
        print(title)
        break
PYEOF
) || NOTE_TITLE="Unnamed"

if [ -z "$NOTE_TITLE" ]; then
  NOTE_TITLE="Unnamed"
fi

# --- Extract inline metadata fields ---
INLINE_META=$(python3 - "$FILE_CONTENT" "$NOTE_TYPE" << 'PYEOF'
import json, re, sys

content = sys.argv[1]
note_type = sys.argv[2]

fields = {}
for line in content.splitlines():
    m = re.match(r'^\*\*([^*]+):\*\*\s*(.*)', line.strip())
    if m:
        key = m.group(1).strip().lower().replace(' ', '_')
        val = m.group(2).strip()
        if val:
            fields[key] = val

if note_type == "plan":
    result = {
        "goal": fields.get("goal", ""),
        "tech_stack": fields.get("tech_stack", ""),
        "spec_ref": fields.get("design_spec", fields.get("spec", "")),
    }
else:
    result = {
        "ticket": fields.get("ticket", ""),
        "scope": fields.get("scope", ""),
    }

print(json.dumps(result))
PYEOF
) || INLINE_META="{}"

# --- Generate summary and tags using Claude ---
if [ "$NOTE_TYPE" = "plan" ]; then
  TYPE_INSTRUCTION="engineering plan"
else
  TYPE_INSTRUCTION="engineering design spec"
fi

CLAUDE_OUTPUT=$(echo "$FILE_CONTENT" | claude -p \
  --bare \
  --max-turns 1 \
  --model claude-haiku-4-5-20251001 \
  --output-format text \
  --system-prompt "You are a concise note-taking assistant. Given an ${TYPE_INSTRUCTION}, output exactly two lines:
Line 1: A 1-2 sentence summary (max 200 chars). Be specific about what will be built or changed.
Line 2: 1-2 lowercase kebab-case tags relevant to the topic (comma-separated, no # prefix).
Output ONLY these two lines." \
  "Summarise and tag this ${TYPE_INSTRUCTION}:" 2>/dev/null) || CLAUDE_OUTPUT=""

SUMMARY=$(echo "$CLAUDE_OUTPUT" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
NEW_TAGS=$(echo "$CLAUDE_OUTPUT" | tail -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Fallback summary
if [ -z "$SUMMARY" ] || [ ${#SUMMARY} -gt 300 ]; then
  SUMMARY=$(python3 - "$FILE_CONTENT" << 'PYEOF'
import re, sys

text = sys.argv[1]
text = re.sub(r'```.*?```', ' ', text, flags=re.S)
text = re.sub(r'^#+\s*', '', text, flags=re.M)
text = re.sub(r'^\|.*\|$', ' ', text, flags=re.M)
text = re.sub(r'^\s*[-*]\s+', '', text, flags=re.M)
text = re.sub(r'\s+', ' ', text).strip()

m = re.search(r'Context\s+(.*?)(Approach|Architecture|Design|Implementation|Verification|$)', text, flags=re.I)
if m:
    text = m.group(1).strip()

text = text[:200].rstrip()
print(text + ("..." if len(text) == 200 else "") if text else "Captured from Claude Code superpowers.")
PYEOF
  )
fi

if [ -z "$NEW_TAGS" ]; then
  NEW_TAGS="engineering-${NOTE_TYPE}"
fi

SUMMARY=$(echo "$SUMMARY" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# --- Build vault paths ---
if [ "$NOTE_TYPE" = "plan" ]; then
  VAULT_DIR="Projects/Engineering/Plans"
else
  VAULT_DIR="Projects/Engineering/Specs"
fi

NOTE_PATH="${VAULT_DIR}/${VAULT_FILENAME}"
JOURNAL_PATH="Journal/${YEAR}/${MONTH_DIR}/${DATE_PREFIX}"

{
  echo "NOTE_TYPE=$NOTE_TYPE"
  echo "NOTE_TITLE=$NOTE_TITLE"
  echo "NOTE_PATH=$NOTE_PATH"
  echo "JOURNAL_PATH=$JOURNAL_PATH"
} >> "$DEBUG_LOG"

# --- Build YAML frontmatter ---
if [ "$NOTE_TYPE" = "plan" ]; then
  GOAL=$(echo "$INLINE_META" | jq -r '.goal')
  TECH_STACK=$(echo "$INLINE_META" | jq -r '.tech_stack')
  SPEC_REF=$(echo "$INLINE_META" | jq -r '.spec_ref')

  FRONTMATTER="---
created: ${DATE_CREATED}
status: planned
tags:
  - plan
  - claude-session
source: Claude Code (Superpowers)
session: ${SESSION_ID}
hook_event: ${HOOK_EVENT}
source_type: tool_input.content
source_file: ${FILE_PATH}
goal: \"${GOAL}\"
tech_stack: \"${TECH_STACK}\"
spec_ref: \"${SPEC_REF}\"
---"
else
  TICKET=$(echo "$INLINE_META" | jq -r '.ticket')
  SCOPE=$(echo "$INLINE_META" | jq -r '.scope')

  FRONTMATTER="---
created: ${DATE_CREATED}
status: planned
tags:
  - spec
  - claude-session
source: Claude Code (Superpowers)
session: ${SESSION_ID}
hook_event: ${HOOK_EVENT}
source_type: tool_input.content
source_file: ${FILE_PATH}
ticket: \"${TICKET}\"
scope: \"${SCOPE}\"
---"
fi

if [ "$NOTE_TYPE" = "plan" ]; then
  SECTION_HEADING="Plan"
else
  SECTION_HEADING="Spec"
fi

NOTE_CONTENT="${FRONTMATTER}

# ${NOTE_TITLE}

## Logged In
[[${JOURNAL_PATH}]]

## ${SECTION_HEADING}

${FILE_CONTENT}
"

# --- Write to vault ---
ESCAPED_CONTENT=$(echo "$NOTE_CONTENT" | sed ':a;N;$!ba;s/\n/\\n/g' | sed "s/'/'\\\\''/g")

obsidian vault=idl create path="${NOTE_PATH}" content="${ESCAPED_CONTENT}" overwrite silent 2>/dev/null || {
  echo "Failed to create ${NOTE_TYPE} note at ${NOTE_PATH}" >> "$DEBUG_LOG"
  exit 0
}

# --- Append journal entry ---
if [ "$NOTE_TYPE" = "plan" ]; then
  ENTRY_LABEL="planned"
else
  ENTRY_LABEL="spec"
fi

JOURNAL_ENTRY="- [[${NOTE_PATH}|${NOTE_TITLE}]] (${ENTRY_LABEL})\n  - ${SUMMARY}"

obsidian vault=idl append path="${JOURNAL_PATH}.md" content="${JOURNAL_ENTRY}" 2>/dev/null || {
  obsidian vault=idl daily:append content="${JOURNAL_ENTRY}" 2>/dev/null || {
    echo "Failed to append journal entry" >> "$DEBUG_LOG"
  }
}

# --- Update daily note tags ---
DAILY_PATH=$(obsidian vault=idl daily:path 2>/dev/null) || DAILY_PATH=""

if [ -n "$DAILY_PATH" ]; then
  EXISTING_TAGS=$(obsidian vault=idl property:read name="tags" path="${DAILY_PATH}" 2>/dev/null | grep -v '^Error:') || EXISTING_TAGS=""

  MERGED_TAGS=$(python3 - "$EXISTING_TAGS" "$NEW_TAGS" << 'PYEOF'
import sys

existing = [t.strip() for t in sys.argv[1].split("\n") if t.strip()]
new = [t.strip() for t in sys.argv[2].split(",") if t.strip()]

seen = set()
merged = []
for tag in existing + new:
    if tag not in seen:
        seen.add(tag)
        merged.append(tag)

print(",".join(merged))
PYEOF
  ) || MERGED_TAGS=""

  if [ -n "$MERGED_TAGS" ]; then
    obsidian vault=idl property:set name="tags" value="${MERGED_TAGS}" type=list path="${DAILY_PATH}" 2>/dev/null || {
      echo "Failed to set tags on daily note" >> "$DEBUG_LOG"
    }
  fi
fi

echo "Successfully captured ${NOTE_TYPE}: ${NOTE_PATH}" >> "$DEBUG_LOG"
exit 0
