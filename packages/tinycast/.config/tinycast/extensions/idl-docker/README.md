# IDL Docker in Tinycast

This Raycast API extension runs in Tinycast. It lists IDL worktrees and starts or stops Docker Compose services with optional extra profiles.

## Setup

1. Commit and push changes from `~/Developer/repos/ammonkc/dotfiles`, then update the deployed checkout at `~/.dotfiles` and run `dotfiles dot:install` to stow the Tinycast script commands. Stow excludes the extension source and dependencies.
2. Run `dotfiles dot:tinycast:extension`. The `dotfiles` wrapper runs Task in `~/.dotfiles`, so the bundle is built at `~/.dotfiles/packages/tinycast/.config/tinycast/extensions/idl-docker/build/`. The task prints the absolute path. When developing before deployment, `task dot:tinycast:extension` in the development checkout builds a separate bundle there.
3. In Tinycast **Settings > Extensions**, enable extensions, choose **Add from folder**, and select the build folder printed by the task. Tinycast copies the bundle into its Application Support directory. `~/.config/tinycast/extensions/idl-docker/build/` is not the build location. Rebuild and add the folder again after source changes.
4. Set **Worktrees Directory** to the parent of your IDL worktrees. The default is `~/Developer/code/indirect`; **Default Worktree** is `main`; **Allegro Domain** defaults to `indirect.test`.
5. In Tinycast **Settings > Commands**, enable custom commands, choose **Import Raycast Scripts**, and select `~/.config/tinycast/script-commands`. Repeat the import after adding new scripts.

Both extension commands call `~/.local/bin/idl-up` and `~/.local/bin/idl-down`; install the `bin` dotfiles package before using them. The extension passes the configured worktree directory to those helpers. The files in `script-commands/` are separate commands and use `~/Developer/code/indirect` by default.

Tinycast currently reads Raycast script titles and argument prompts, but ignores icon headers and dropdown choices. Enter values such as Docker task names as text when prompted.

## Commands

- **Start Containers**: choose a worktree; optionally add profiles such as `queue, worker`.
- **Stop Containers**: choose a worktree and optional profiles.

The extension preserves the scripts' default Compose profiles. The separate IDL Up script command also accepts `--build` in its third argument, for example `queue, --build`.
