# IDL Docker in Raycast

Manage IDL Docker Compose services across git worktrees. Both commands call
`~/.local/bin/idl-up` or `~/.local/bin/idl-down` and pass the configured
Worktrees Directory to the helpers. Install the `bin` dotfiles package first.

## Setup

From the deployed checkout, run `dotfiles dot:raycast:extension` to install
dependencies and register the extension in Raycast development mode. From the
development checkout, run `task dot:raycast:extension` instead.
Keep that task running while using the local extension.
`npm run build` compiles into this checkout's ignored `build/` directory.

Set **Worktrees Directory** to the parent of your IDL worktrees. The default is
`~/Developer/code/indirect`; **Default Worktree** is `main`; **Allegro Domain**
defaults to `indirect.test`.

## Commands

- **Start Containers** starts the selected worktree with the default `sftp`
  profile. **Start with Queue** also enables `queue`.
- **Stop Containers** stops the selected worktree with both `sftp` and `queue`
  profiles, matching the shared `idl-down` helper.

Raycast shows Docker output as it arrives and keeps the last 12 lines visible.
**Copy Output** copies the full result. The separate IDL script commands under
`~/.config/raycast/script-commands/` use the same stowed helpers and accept
`queue` and `--build` in the third argument.
