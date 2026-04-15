#!/bin/bash
set -euo pipefail

# Skip if cmux isn't available
command -v cmux >/dev/null 2>&1 || exit 0

STATUS_KEY="claude"
STATE_DIR="/tmp/cmux-claude-progress"
mkdir -p "$STATE_DIR"

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
STATE_FILE="$STATE_DIR/$SESSION_ID"

case "$EVENT" in
  UserPromptSubmit)
    echo "$INPUT" | cmux claude-hook prompt-submit
    cmux workspace-action set-color Amber

    # Reset tool counter; preserve plan steps if they exist from ExitPlanMode
    TOTAL=$(jq -r '.total_steps // 0' "$STATE_FILE" 2>/dev/null || echo 0)
    STEPS=$(jq -r '.steps // "[]"' "$STATE_FILE" 2>/dev/null || echo "[]")
    echo "{\"current_step\":0,\"total_steps\":$TOTAL,\"steps\":$STEPS}" > "$STATE_FILE"

    cmux set-status "$STATUS_KEY" "working" --icon sparkle --color "#F59E0B"
    if [ "$TOTAL" -gt 0 ]; then
      cmux set-progress 0.0 --label "Step 0/$TOTAL"
    else
      cmux set-progress 0.0 --label "Starting..."
    fi
    cmux clear-log
    cmux log --level info --source claude "Turn started"
    ;;

  PostToolUse)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
    if [ "$TOOL" = "ExitPlanMode" ]; then
      # Parse plan steps from the plan content
      PLAN=$(echo "$INPUT" | jq -r '.tool_response.plan // empty')
      if [ -z "$PLAN" ]; then
        PLAN_FILE=$(echo "$INPUT" | jq -r '.tool_response.filePath // empty')
        if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
          PLAN=$(cat "$PLAN_FILE")
        fi
      fi

      if [ -n "$PLAN" ]; then
        # Extract step headings (### Step N: ... or ## Step N: ...)
        STEPS_JSON=$(echo "$PLAN" | grep -E '^#{2,3}\s+Step\s+[0-9]+' | sed 's/^#*\s*//' | jq -R -s 'split("\n") | map(select(length > 0))')
        TOTAL=$(echo "$STEPS_JSON" | jq 'length')

        if [ "$TOTAL" -gt 0 ]; then
          echo "{\"current_step\":0,\"total_steps\":$TOTAL,\"steps\":$STEPS_JSON}" > "$STATE_FILE"
          cmux set-progress 0.0 --label "Plan: $TOTAL steps"
          cmux log --level info --source claude "Plan loaded: $TOTAL steps"

          # Log each step name
          echo "$STEPS_JSON" | jq -r '.[]' | while read -r STEP_NAME; do
            cmux log --level info --source claude "  $STEP_NAME"
          done
        fi
      fi
    fi
    ;;

  PreToolUse)
    TOOL=$(echo "$INPUT" | jq -r '.tool_name // "tool"')
    cmux set-status "$STATUS_KEY" "$TOOL" --icon sparkle --color "#F59E0B"
    cmux workspace-action --action set-description --description "Running: $TOOL"

    # Increment step counter and update progress if plan exists
    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(jq -r '.current_step // 0' "$STATE_FILE")
      TOTAL=$(jq -r '.total_steps // 0' "$STATE_FILE")
      STEPS=$(jq -r '.steps // "[]"' "$STATE_FILE")

      if [ "$TOTAL" -gt 0 ]; then
        # Plan-based progress: step N of total
        CURRENT=$((CURRENT + 1))
        if [ "$CURRENT" -gt "$TOTAL" ]; then
          CURRENT=$TOTAL
        fi
        PROGRESS=$(echo "scale=2; $CURRENT / ($TOTAL + 1)" | bc)
        STEP_NAME=$(echo "$STEPS" | jq -r ".[$((CURRENT - 1))] // empty")
        LABEL="Step $CURRENT/$TOTAL"
        if [ -n "$STEP_NAME" ]; then
          LABEL="$STEP_NAME"
        fi
        echo "{\"current_step\":$CURRENT,\"total_steps\":$TOTAL,\"steps\":$STEPS}" > "$STATE_FILE"
        cmux set-progress "$PROGRESS" --label "$LABEL"
        cmux log --level progress --source claude "$LABEL: $TOOL"
      else
        # No plan: heuristic progress, asymptotically approach 0.9
        CURRENT=$((CURRENT + 1))
        # Formula: 0.9 * (1 - 1/(1 + current*0.15)) — rises fast then plateaus
        PROGRESS=$(echo "scale=2; 0.9 * (1 - 1/(1 + $CURRENT * 0.15))" | bc)
        echo "{\"current_step\":$CURRENT,\"total_steps\":0,\"steps\":[]}" > "$STATE_FILE"
        cmux set-progress "$PROGRESS" --label "$TOOL"
        cmux log --level info --source claude "$TOOL"
      fi
    fi
    ;;

  Notification)
    echo "$INPUT" | cmux claude-hook notification
    cmux workspace-action mark-unread
    ;;

  Stop)
    echo "$INPUT" | cmux claude-hook stop
    cmux workspace-action set-color Green
    cmux workspace-action clear-description
    cmux set-progress 1.0 --label "Done"
    cmux set-status "$STATUS_KEY" "idle" --icon sparkle --color "#10B981"
    cmux log --level success --source claude "Turn complete"
    cmux notify --title "Claude Code" --body "Turn complete"
    ;;

  StopFailure)
    echo "$INPUT" | cmux claude-hook stop
    cmux workspace-action set-color Red
    cmux workspace-action --action set-description --description "Error"
    cmux set-progress 1.0 --label "Failed"
    cmux set-status "$STATUS_KEY" "error" --icon sparkle --color "#EF4444"
    cmux log --level error --source claude "Turn failed"
    cmux trigger-flash
    cmux notify --title "Claude Code" --body "Turn failed (API error)"
    ;;

  SessionEnd)
    echo "$INPUT" | cmux claude-hook stop
    cmux workspace-action clear-color
    cmux workspace-action clear-description
    cmux clear-progress
    cmux clear-status "$STATUS_KEY"
    cmux log --level info --source claude "Session ended"
    rm -f "$STATE_FILE"
    ;;
esac

exit 0
