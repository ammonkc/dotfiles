---
name: report
description: Write research or deep-dive findings as a markdown report that is auto-saved to Obsidian (Projects/Engineering/Research). Use when the task is research, investigation, or code exploration that does not lead to edits or an implementation plan, or when the user types /report.
---

Present the findings as a report instead of a long chat answer.

1. Pick a short descriptive title. Filename: `~/.claude/reports/<MM-DD-YYYY>-<kebab-slug>.md` (date is today's date).
2. Write it with the Write tool, exactly this shape:

```
---
title: <descriptive title>
summary: <1-2 sentences, max 200 chars, what was found>
tags: <1-3 lowercase kebab-case tags, comma-separated>
---

## Question
## Summary
## Findings
(each finding with file:line anchors or source links)
## Open questions
```

3. A PostToolUse hook copies it to the vault and adds a journal entry. Do not copy it yourself.
4. Reply in chat with only the file path and a 1-2 sentence takeaway.

Do not use this when the work ends in a plan that needs approval (use plan mode) or when the user asked a quick factual question.
