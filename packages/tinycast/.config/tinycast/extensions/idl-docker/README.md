# IDL Docker in Tinycast

This Raycast API extension runs in Tinycast. It lists IDL worktrees and starts or stops Docker Compose services with optional extra profiles.

## Setup

1. Stow the Tinycast script commands with `task dot:restow PACKAGE=tinycast` (or run the normal dotfiles install task). Stow excludes the extension source and dependencies.
2. Build the extension with `task dot:tinycast:extension`. This installs dependencies and writes a bundle to `build/` in this directory.
3. In Tinycast **Settings > Extensions**, enable extensions, choose **Add from folder**, and select this directory's `build/` folder. Tinycast copies the bundle into its library. Rebuild and add the folder again after source changes.
4. Set **Worktrees Directory** to the parent of your IDL worktrees. The default is `~/Developer/code/indirect`; **Default Worktree** is `main`; **Allegro Domain** defaults to `indirect.test`.
5. In Tinycast **Settings > Commands**, enable custom commands, choose **Import Raycast Scripts**, and select `~/.config/tinycast/script-commands`. Repeat the import after adding new scripts.

Both extension commands call `~/.local/bin/idl-up` and `~/.local/bin/idl-down`; install the `bin` dotfiles package before using them. The extension passes the configured worktree directory to those helpers. The files in `script-commands/` are separate commands and use `~/Developer/code/indirect` by default.

Tinycast currently reads Raycast script titles and argument prompts, but ignores icon headers and dropdown choices. Enter values such as Docker task names as text when prompted.

## Commands

- **Start Containers**: choose a worktree; optionally add profiles such as `queue, worker`.
- **Stop Containers**: choose a worktree and optional profiles.

The extension preserves the scripts' default Compose profiles. The separate IDL Up script command also accepts `--build` in its third argument, for example `queue, --build`.
