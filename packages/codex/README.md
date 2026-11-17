# Codex

This package stows `~/.codex/AGENTS.md` with the shared worktree convention.
Agent-created worktrees use `agent-worktree create --tool codex --repo REPO NAME`,
which creates `codex/NAME` under
`~/Developer/worktrees/<remote-repo-name>/codex-NAME/` through Worktrunk.

This is an instruction-based convention, not an override for Codex's managed
worktree UI or `codex --worktree`. To start a session in the exact shared layout:

```sh
worktree=$(agent-worktree create --tool codex --repo "$PWD" task-name)
codex -C "$worktree"
```

The managed native worktree lifecycle is left intact. No unsupported path
settings are added to config.toml, and existing user configuration is preserved.
Official documentation endpoints returned HTTP 403 during implementation; the
installed CLI does not expose a custom creation-hook interface in its help.
