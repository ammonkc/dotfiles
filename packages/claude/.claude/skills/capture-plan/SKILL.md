---
name: capture-plan
description: Manually capture and save a plan to Obsidian vault when the ExitPlanMode hook didn't fire
---

## When to Use

You selected "Tell Claude what to change" in plan mode, and the plan was NOT automatically saved to your Obsidian vault. This skill replays the `capture-plan.sh` hook to save it manually.

## How It Works

1. Resolves the plan file path (uses your current session's plan file from context, or finds the most recent `.md` in `~/.claude/plans/`)
2. Pipes a crafted JSON payload to `~/.claude/hooks/capture-plan.sh` to trigger the same vault-save logic
3. Reports success from the hook's debug log

## What Happens

Running this skill will:
- Extract the plan title and generate a slug
- Create a note in your Obsidian vault at `Projects/Engineering/Plans/<MM-DD-YYYY>-<slug>.md`
- Append an entry to your daily journal
- Add or merge tags on the daily note

## Usage

Simply invoke the skill:

```
/capture-plan
```

Or pass the plan file path explicitly:

```
/capture-plan path=/path/to/plan/file.md
```

If no path is provided, the script finds the most recently modified `.md` file in `~/.claude/plans/`.

## Debug

If the plan isn't appearing in your vault, check:
- Your Obsidian vault is accessible at the path stored in `obsidian vault info=path`
- The plan file exists and has at least 20 characters of content
- Check `/tmp/capture-plan-debug.log` for error details
