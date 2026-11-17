# OpenCode

Requires OpenCode 2.3 or newer. This package stows global agent instructions,
a non-secret settings fragment, and a local Worktrunk worktree strategy.

After stowing bin, claude, codex, opencode, and worktrunk, run
`dotfiles dot:agents:worktrees`. This installs the local strategy dependencies and
merges its registration into existing user settings without copying credentials
into dotfiles. Restart OpenCode after configuring. The real opencode.json remains
unmanaged; global AGENTS.md also gives agents the shared CLI convention.

The native worktree UI uses the strategy to create `opencode/<requested-name>`
branches under `~/Developer/worktrees/<remote-repo-name>/opencode-<name>/`.
A requested starting branch remains the starting ref, not the new branch name.
Worktrunk performs dependency setup and IDL task installation before returning.
The strategy reports its own worktrees and the primary checkout, retains branches
on removal, and only honors force removal when OpenCode explicitly requests it.
Existing worktrees retain their previous OpenCode strategy ownership.

OpenCode permits other plugins to register strategies; the last active strategy
wins. Do not register a competing strategy if this should remain the default.

References: [OpenCode worktree configuration](https://opencode.ai/docs/config/#worktrees)
and [worktree strategies](https://opencode.ai/docs/build/plugins/server#worktrees).
