# Herdr

Manage Herdr's portable configuration at `~/.config/herdr/config.toml` through
Stow. Only explicit preferences belong in this package; logs, sessions, saved
machines, and other generated state remain unmanaged.

The worktree parent is `~/Developer/worktrees`. Herdr appends its own repository
name and branch slug. This sets Herdr's native Git worktree destination; it does
not replace creation with Worktrunk or automatically run the dotfiles setup hooks.
For an IDL worktree created by Herdr, run `git-worktree-setup` and
`idl-worktree-setup` in that checkout to copy selected dependencies and install
Zed tasks. Existing worktrees are not moved by this setting.

After deploying this commit:

```sh
dotfiles dot:restow PACKAGE=herdr
herdr config check
herdr server reload-config
```

Reload applies the configuration to a running Herdr server. If none is running,
launch Herdr normally and it will read the file. Make durable configuration edits
in this development package, then deploy them through the normal dotfiles flow.

Reference: [Herdr configuration](https://herdr.dev/tui/docs/configuration/).
