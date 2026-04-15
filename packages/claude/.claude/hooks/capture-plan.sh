#!/bin/bash
# ============================================================
# capture-plan.sh — Claude Code Hook for ExitPlanMode
# ============================================================

set -euo pipefail

DEBUG_LOG="/tmp/capture-plan-debug.log"

INPUT=$(cat)

{
  echo "=== $(date) ==="
  echo "$INPUT"
  echo "---"
} >> "$DEBUG_LOG"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL_NAME" != "ExitPlanMode" ]; then
  exit 0
fi

HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

PLAN_CONTENT=""
PLAN_FILE=""
PLAN_SOURCE="unknown"

# 1) PostToolUse inline plan
PLAN_CONTENT=$(echo "$INPUT" | jq -r '.tool_response.plan // empty')
if [ -n "$PLAN_CONTENT" ] && [ "$PLAN_CONTENT" != "null" ]; then
  PLAN_SOURCE="tool_response.plan"
fi

# 2) PostToolUse file fallback
if [ -z "$PLAN_CONTENT" ]; then
  PLAN_FILE=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')
  if [ -n "$PLAN_FILE" ] && [ "$PLAN_FILE" != "null" ] && [ -f "$PLAN_FILE" ]; then
    PLAN_CONTENT=$(cat "$PLAN_FILE")
    PLAN_SOURCE="tool_response.filePath"
  fi
fi

# 3) PermissionRequest inline plan
if [ -z "$PLAN_CONTENT" ]; then
  PLAN_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.plan // empty')
  if [ -n "$PLAN_CONTENT" ] && [ "$PLAN_CONTENT" != "null" ]; then
    PLAN_SOURCE="tool_input.plan"
  fi
fi

# 4) PermissionRequest file fallback
if [ -z "$PLAN_CONTENT" ]; then
  PLAN_FILE=$(echo "$INPUT" | jq -r '.tool_input.planFilePath // empty')
  if [ -n "$PLAN_FILE" ] && [ "$PLAN_FILE" != "null" ] && [ -f "$PLAN_FILE" ]; then
    PLAN_CONTENT=$(cat "$PLAN_FILE")
    PLAN_SOURCE="tool_input.planFilePath"
  fi
fi

if [ -z "$PLAN_CONTENT" ] || [ "$PLAN_CONTENT" = "null" ] || [ ${#PLAN_CONTENT} -lt 20 ]; then
  {
    echo "No valid plan content found"
    echo "HOOK_EVENT=$HOOK_EVENT"
    echo "PLAN_SOURCE=$PLAN_SOURCE"
    echo "PLAN_FILE=$PLAN_FILE"
  } >> "$DEBUG_LOG"
  exit 0
fi

# --- Extract plan title, slug, and date metadata ---
EXTRACTED=$(python3 - "$PLAN_CONTENT" << 'PYEOF'
import json, re, sys
from datetime import datetime

plan_content = sys.argv[1]

title = "Unnamed Plan"

for raw_line in plan_content.splitlines():
    line = raw_line.strip()
    if not line:
        continue

    # Remove markdown heading markers only
    line = re.sub(r'^#+\s*', '', line)

    # Remove leading "Plan:" only
    line = re.sub(r'^(plan:)\s*', '', line, flags=re.I)

    # Normalise whitespace
    line = re.sub(r'\s+', ' ', line).strip()

    if line:
        title = line
        break

# Clean display title, but DO NOT abbreviate words
title = re.sub(r'[`*_]', '', title)
title = re.sub(r'\s+', ' ', title).strip()
title = title or "Unnamed Plan"

# Build filename slug separately
slug = title.lower()
slug = slug.replace("&", " and ")
slug = re.sub(r'[^a-z0-9\s-]', '', slug)
slug = re.sub(r'\s+', '-', slug)
slug = re.sub(r'-+', '-', slug).strip('-')

STOP_WORDS = {"a", "an", "the", "with", "and", "of", "for", "to"}

words = [w for w in slug.split('-') if w]
if len(words) > 6:
    filtered = [
        w for i, w in enumerate(words)
        if not (w in STOP_WORDS and i != 0 and i != len(words) - 1)
    ]
    slug = '-'.join(filtered) or slug

if len(slug) > 80:
    parts = slug.split('-')
    kept = []
    total = 0
    for part in parts:
        extra = len(part) + (1 if kept else 0)
        if total + extra > 80:
            break
        kept.append(part)
        total += extra
    slug = '-'.join(kept) or slug

now = datetime.now()

print(json.dumps({
    "plan_title": title,
    "plan_slug": slug or "unnamed-plan",
    "date_prefix": now.strftime("%m-%d-%Y"),
    "created_at": now.strftime("%m/%d/%Y"),
    "year": now.strftime("%Y"),
    "month_dir": now.strftime("%m-%B"),
}))
PYEOF
) || exit 0

if [ -z "$EXTRACTED" ] || [ "$EXTRACTED" = "null" ]; then
  exit 0
fi

PLAN_TITLE=$(echo "$EXTRACTED" | jq -r '.plan_title')
PLAN_SLUG=$(echo "$EXTRACTED" | jq -r '.plan_slug')
DATE_PREFIX=$(echo "$EXTRACTED" | jq -r '.date_prefix')
CREATED_AT=$(echo "$EXTRACTED" | jq -r '.created_at')
YEAR=$(echo "$EXTRACTED" | jq -r '.year')
MONTH_DIR=$(echo "$EXTRACTED" | jq -r '.month_dir')

PLAN_FILENAME="${DATE_PREFIX}-${PLAN_SLUG}"
PLAN_PATH="Projects/Engineering/Plans/${PLAN_FILENAME}"
JOURNAL_PATH="Journal/${YEAR}/${MONTH_DIR}/${DATE_PREFIX}"

{
  echo "HOOK_EVENT=$HOOK_EVENT"
  echo "PLAN_SOURCE=$PLAN_SOURCE"
  echo "PLAN_FILE=$PLAN_FILE"
  echo "PLAN_TITLE=$PLAN_TITLE"
  echo "PLAN_SLUG=$PLAN_SLUG"
  echo "PLAN_FILENAME=$PLAN_FILENAME"
} >> "$DEBUG_LOG"

# --- Generate summary and tags using Claude ---
CLAUDE_OUTPUT=$(echo "$PLAN_CONTENT" | claude -p \
  --bare \
  --max-turns 1 \
  --model claude-haiku-4-5-20251001 \
  --output-format text \
  --system-prompt "You are a concise note-taking assistant. Given an engineering plan, output exactly two lines:
Line 1: A 1-2 sentence summary (max 200 chars). Be specific about what will be built or changed.
Line 2: 1-2 lowercase kebab-case tags relevant to the plan topic (comma-separated, no # prefix).
Output ONLY these two lines." \
  "Summarise and tag this plan:" 2>/dev/null) || CLAUDE_OUTPUT=""

SUMMARY=$(echo "$CLAUDE_OUTPUT" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
NEW_TAGS=$(echo "$CLAUDE_OUTPUT" | tail -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Fallback summary
if [ -z "$SUMMARY" ] || [ ${#SUMMARY} -gt 300 ]; then
  SUMMARY=$(python3 - "$PLAN_CONTENT" << 'PYEOF'
import re, sys

text = sys.argv[1]
text = re.sub(r'```.*?```', ' ', text, flags=re.S)
text = re.sub(r'^#+\s*', '', text, flags=re.M)
text = re.sub(r'^\|.*\|$', ' ', text, flags=re.M)
text = re.sub(r'^\s*[-*]\s+', '', text, flags=re.M)
text = re.sub(r'^(Plan:|PLAN:)\s*', '', text, flags=re.M)
text = re.sub(r'\s+', ' ', text).strip()

m = re.search(r'Context\s+(.*?)(Approach|Architecture Decisions|Project Structure|Routing|Data Storage|Implementation Steps|Verification|$)', text, flags=re.I)
if m:
    text = m.group(1).strip()

text = text[:200].rstrip()
print(text + ("..." if len(text) == 200 else "") if text else "Captured an engineering plan from Claude Code.")
PYEOF
)
fi

if [ -z "$NEW_TAGS" ]; then
  NEW_TAGS="engineering-plan"
fi

SUMMARY=$(echo "$SUMMARY" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

NOTE_CONTENT="---
created: ${CREATED_AT}
status: planned
tags:
  - plan
  - claude-session
source: Claude Code (Plan Mode)
session: ${SESSION_ID}
hook_event: ${HOOK_EVENT}
source_type: ${PLAN_SOURCE}
source_file: ${PLAN_FILE}
---

# ${PLAN_TITLE}

## Logged In
[[${JOURNAL_PATH}]]

## Plan

${PLAN_CONTENT}
"

ESCAPED_CONTENT=$(echo "$NOTE_CONTENT" | sed ':a;N;$!ba;s/\n/\\n/g' | sed "s/'/'\\\\''/g")

obsidian create path="${PLAN_PATH}" content="${ESCAPED_CONTENT}" silent 2>/dev/null || {
  echo "Failed to create plan note" >> "$DEBUG_LOG"
  exit 0
}

JOURNAL_ENTRY="- [[${PLAN_PATH}|${PLAN_TITLE}]] (planned)\n  - ${SUMMARY}"

obsidian append path="${JOURNAL_PATH}.md" content="${JOURNAL_ENTRY}" 2>/dev/null || {
  obsidian daily:append content="${JOURNAL_ENTRY}" 2>/dev/null || {
    echo "Failed to append journal entry" >> "$DEBUG_LOG"
  }
}

DAILY_PATH=$(obsidian daily:path 2>/dev/null) || DAILY_PATH=""

if [ -n "$DAILY_PATH" ]; then
  EXISTING_TAGS=$(obsidian property:read name="tags" path="${DAILY_PATH}" 2>/dev/null | grep -v '^Error:') || EXISTING_TAGS=""

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
    obsidian property:set name="tags" value="${MERGED_TAGS}" type=list path="${DAILY_PATH}" 2>/dev/null || {
      echo "Failed to set tags" >> "$DEBUG_LOG"
    }
  fi
fi

exit 0
