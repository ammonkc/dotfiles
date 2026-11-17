# OpenCode

Requires OpenCode 2.3 or newer. This package stows global agent instructions and
a non-secret settings fragment. The Worktrunk strategy's source, lockfile, and
plugin tests live in [claude-fiyah](https://github.com/ammonkc/claude-fiyah), under
`opencode/worktrunk/`. The primary checkout must contain that reviewed package
before activation; a completed agent worktree alone is not sufficient.

After stowing bin, claude, codex, opencode, and worktrunk, run
`dotfiles dot:agents:worktrees`. This installs the external strategy dependencies and
merges its registration into existing user settings without copying credentials
into dotfiles. Restart OpenCode after configuring. The real opencode.json remains
unmanaged; global AGENTS.md also gives agents the shared CLI convention.

The task defaults to `~/Developer/repos/ammonkc/claude-fiyah/opencode/worktrunk`.
It validates that the package exists before changing user settings, expands its
configured path to an absolute path, and replaces the previous embedded plugin
registration while preserving unrelated plugins and custom helper-path options.
To test a reviewed package in another checkout before integration:

```sh
dotfiles dot:agents:worktrees OPENCODE_WORKTRUNK_DIR=/absolute/path/to/opencode/worktrunk
```

The shared `agent-worktree` helper, dependency setup, IDL Zed-task installation,
and personal Worktrunk configuration remain in dotfiles. Follow the external
package's README for plugin development and package tests.

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
