# Claude Code

This package stows user instructions, skills, and a non-secret
`~/.claude/worktree-settings.json` fragment. The real `settings.json` remains
unmanaged because it can contain credentials and machine-specific settings.

After stowing bin, claude, codex, opencode, and worktrunk, run
`dotfiles dot:agents:worktrees`. The task merges WorktreeCreate and WorktreeRemove
hooks into existing user settings, preserves other settings, and creates private
backups when changes are needed. Conflicting existing worktree hooks cause an
error rather than running two creators. Restart Claude Code after configuring.

`claude --worktree task-name` and isolated agent worktrees use the shared
`agent-worktree` helper. It creates `claude/task-name` through Worktrunk under
`~/Developer/worktrees/<remote-repo-name>/claude-task-name/` and waits for the
shared dependency and IDL Zed-task hooks. Repeated names fail instead of reusing
another agent's worktree. Cleanup keeps branches and refuses dirty worktrees.
WorktreeCreate hooks do not intercept raw Git commands issued through Bash;
CLAUDE.md provides the same convention for agent-issued commands.

References: [Claude hook lifecycle](https://code.claude.com/docs/en/hooks#worktreecreate).
