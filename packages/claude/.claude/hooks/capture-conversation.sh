#!/bin/bash
# ============================================================
# capture-conversation.sh — Claude Code Hook for ExitPlanMode
# Saves the full session transcript to Obsidian and links it
# back to the plan note created by capture-plan.sh.
# ============================================================

set -euo pipefail

DEBUG_LOG="/tmp/capture-conversation-debug.log"

INPUT=$(cat)

{
  echo "=== $(date) ==="
  echo "$INPUT" | head -c 4000
  echo ""
  echo "---"
} >> "$DEBUG_LOG"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL_NAME" != "ExitPlanMode" ]; then
  exit 0
fi

HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "No transcript_path or file missing: $TRANSCRIPT_PATH" >> "$DEBUG_LOG"
  exit 0
fi

PLAN_CONTENT=""
PLAN_FILE=""

PLAN_CONTENT=$(echo "$INPUT" | jq -r '.tool_response.plan // empty')
if [ -z "$PLAN_CONTENT" ] || [ "$PLAN_CONTENT" = "null" ]; then
  PLAN_FILE=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')
  if [ -n "$PLAN_FILE" ] && [ "$PLAN_FILE" != "null" ] && [ -f "$PLAN_FILE" ]; then
    PLAN_CONTENT=$(cat "$PLAN_FILE")
  fi
fi
if [ -z "$PLAN_CONTENT" ] || [ "$PLAN_CONTENT" = "null" ]; then
  PLAN_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.plan // empty')
fi
if [ -z "$PLAN_CONTENT" ] || [ "$PLAN_CONTENT" = "null" ]; then
  PLAN_FILE=$(echo "$INPUT" | jq -r '.tool_input.planFilePath // empty')
  if [ -n "$PLAN_FILE" ] && [ "$PLAN_FILE" != "null" ] && [ -f "$PLAN_FILE" ]; then
    PLAN_CONTENT=$(cat "$PLAN_FILE")
  fi
fi

if [ -z "$PLAN_CONTENT" ] || [ "$PLAN_CONTENT" = "null" ] || [ ${#PLAN_CONTENT} -lt 20 ]; then
  echo "No valid plan content found" >> "$DEBUG_LOG"
  exit 0
fi

# --- Derive plan slug + date (mirrors capture-plan.sh) ---
EXTRACTED=$(python3 - "$PLAN_CONTENT" << 'PYEOF'
import json, re, sys
from datetime import datetime

plan_content = sys.argv[1]

title = "Unnamed Plan"

for raw_line in plan_content.splitlines():
    line = raw_line.strip()
    if not line:
        continue
    line = re.sub(r'^#+\s*', '', line)
    line = re.sub(r'^(plan:)\s*', '', line, flags=re.I)
    line = re.sub(r'\s+', ' ', line).strip()
    if line:
        title = line
        break

title = re.sub(r'[`*_]', '', title)
title = re.sub(r'\s+', ' ', title).strip()
title = title or "Unnamed Plan"

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

PLAN_FILENAME="${DATE_PREFIX}-${PLAN_SLUG}"
PLAN_PATH="Projects/Engineering/Plans/${PLAN_FILENAME}"

SHORT_SESSION="${SESSION_ID: -6}"
CONTEXT_FILENAME="${DATE_PREFIX}-${PLAN_SLUG}-${SHORT_SESSION}"
CONTEXT_PATH="Projects/Engineering/Contexts/${CONTEXT_FILENAME}"

{
  echo "SESSION_ID=$SESSION_ID"
  echo "TRANSCRIPT_PATH=$TRANSCRIPT_PATH"
  echo "PLAN_PATH=$PLAN_PATH"
  echo "CONTEXT_PATH=$CONTEXT_PATH"
} >> "$DEBUG_LOG"

# --- Render JSONL transcript to markdown ---
RENDERED_FILE=$(mktemp -t conv-rendered.XXXXXX)
trap 'rm -f "$RENDERED_FILE"' EXIT

python3 - "$TRANSCRIPT_PATH" "$RENDERED_FILE" << 'PYEOF'
import json, re, sys

transcript_path = sys.argv[1]
out_path = sys.argv[2]

MAX_RESULT_CHARS = 4000

def strip_system_reminders(text):
    if not text:
        return text
    return re.sub(r'<system-reminder>.*?</system-reminder>\s*', '', text, flags=re.S)

def truncate(text, limit):
    if text is None:
        return ""
    if len(text) <= limit:
        return text
    omitted = len(text) - limit
    return text[:limit] + f"\n... [truncated, {omitted} chars omitted]"

def render_user_content(content):
    out = []
    if isinstance(content, str):
        cleaned = strip_system_reminders(content).strip()
        if cleaned:
            out.append(cleaned)
        return out
    if not isinstance(content, list):
        return out
    for block in content:
        if not isinstance(block, dict):
            continue
        btype = block.get("type")
        if btype == "text":
            cleaned = strip_system_reminders(block.get("text", "")).strip()
            if cleaned:
                out.append(cleaned)
        elif btype == "tool_result":
            tool_id = block.get("tool_use_id", "")
            inner = block.get("content", "")
            if isinstance(inner, list):
                pieces = []
                for sub in inner:
                    if isinstance(sub, dict) and sub.get("type") == "text":
                        pieces.append(sub.get("text", ""))
                    elif isinstance(sub, str):
                        pieces.append(sub)
                inner_text = "\n".join(pieces)
            elif isinstance(inner, str):
                inner_text = inner
            else:
                inner_text = json.dumps(inner, indent=2)
            inner_text = truncate(inner_text, MAX_RESULT_CHARS)
            out.append(f"#### Result (tool_use_id: `{tool_id}`)\n```\n{inner_text}\n```")
    return out

def render_assistant_content(content):
    out = []
    if not isinstance(content, list):
        return out
    for block in content:
        if not isinstance(block, dict):
            continue
        btype = block.get("type")
        if btype == "text":
            text = block.get("text", "").strip()
            if text:
                out.append(text)
        elif btype == "thinking":
            text = block.get("thinking", "").strip()
            if text:
                quoted = "\n".join("> " + line for line in text.splitlines())
                out.append(f"> [!note]- Thinking\n{quoted}")
        elif btype == "tool_use":
            name = block.get("name", "?")
            tool_id = block.get("id", "")
            inp = block.get("input", {})
            try:
                inp_json = json.dumps(inp, indent=2)
            except Exception:
                inp_json = str(inp)
            inp_json = truncate(inp_json, MAX_RESULT_CHARS)
            out.append(f"### Tool: {name} (`{tool_id}`)\n```json\n{inp_json}\n```")
    return out

sections = []
last_role = None

with open(transcript_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except Exception:
            continue
        rtype = rec.get("type")
        if rtype not in ("user", "assistant"):
            continue
        msg = rec.get("message") or {}
        content = msg.get("content")
        if rtype == "user":
            parts = render_user_content(content)
            if parts:
                if last_role != "user":
                    sections.append("## User")
                    last_role = "user"
                sections.extend(parts)
        else:
            parts = render_assistant_content(content)
            if parts:
                if last_role != "assistant":
                    sections.append("## Assistant")
                    last_role = "assistant"
                sections.extend(parts)

with open(out_path, "w", encoding="utf-8") as f:
    f.write("\n\n".join(sections))
PYEOF

if [ ! -s "$RENDERED_FILE" ]; then
  echo "Rendered transcript empty" >> "$DEBUG_LOG"
  exit 0
fi

RENDERED_BODY=$(cat "$RENDERED_FILE")

NOTE_CONTENT="---
created: ${CREATED_AT}
tags:
  - claude-conversation
  - claude-session
source: Claude Code
session: ${SESSION_ID}
transcript_path: ${TRANSCRIPT_PATH}
plan: \"[[${PLAN_PATH}|${PLAN_TITLE}]]\"
---

# Conversation: ${PLAN_TITLE}

> Linked plan: [[${PLAN_PATH}|${PLAN_TITLE}]]

${RENDERED_BODY}
"

ESCAPED_CONTENT=$(printf '%s' "$NOTE_CONTENT" | python3 -c 'import sys; sys.stdout.write(sys.stdin.read().replace("\\", "\\\\").replace("\n", "\\n"))')

obsidian create path="${CONTEXT_PATH}" content="${ESCAPED_CONTENT}" overwrite 2>/dev/null || {
  echo "Failed to create context note" >> "$DEBUG_LOG"
  exit 0
}

# --- Append backlink to plan note (idempotent) ---
EXISTING_PLAN=$(obsidian read path="${PLAN_PATH}.md" 2>/dev/null || echo "")

if ! echo "$EXISTING_PLAN" | grep -q "^## Conversation"; then
  CONV_LINK_RAW="

## Conversation
[[${CONTEXT_PATH}|${CONTEXT_FILENAME}]]
"
  CONV_LINK_ESCAPED=$(printf '%s' "$CONV_LINK_RAW" | python3 -c 'import sys; sys.stdout.write(sys.stdin.read().replace("\\", "\\\\").replace("\n", "\\n"))')
  obsidian append path="${PLAN_PATH}.md" content="${CONV_LINK_ESCAPED}" 2>/dev/null || {
    echo "Failed to append conversation link to plan" >> "$DEBUG_LOG"
  }
fi

exit 0
