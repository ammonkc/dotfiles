# Worktree workflow

When creating worktrees, use `agent-worktree create --tool codex --repo /path/to/repo task-name`.
Use the returned absolute directory. The helper creates a codex/task-name branch
from the source checkout's current commit and uses Worktrunk for setup.
Worktrees live in `~/Developer/worktrees/<remote-repo-name>/<sanitized-branch>/`.
Use the remote repository name, not a renamed checkout's directory name.

Reuse an existing worktree when the user asks to work there. Do not move existing
worktrees or create another checkout for the same task. Do not use tool-specific
hidden worktree directories or raw `git worktree add` for new worktrees unless
the user explicitly requests it. Report missing helpers or creation failures;
do not silently fall back to another directory. To remove a worktree, use
`agent-worktree remove --tool codex /absolute/worktree/path` when authorized.
Branches are retained and dirty worktrees are refused by default.

The shared Worktrunk setup hook copies ignored files selected by the primary
checkout's local `.worktreeinclude`. IDL also installs its Zed tasks with
`idl-worktree-setup`. Do not copy MySQL data directories as dependency setup.

Do not push commits unless the user explicitly asks.

Use this workflow instead of Codex-managed worktree creation when the shared
per-repository layout is required. These instructions guide agent actions;
they do not change a host application’s built-in worktree creation UI.
