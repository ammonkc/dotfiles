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

## Script command confirmations

Tinycast imports Raycast `compact` and `fullOutput` modes with **Show output** enabled, which opens an output window instead of showing a brief success message. In Tinycast **Settings > Commands**, edit an imported command and turn **Show output** off and **Show confirmation** on to show a brief message after it succeeds. Tinycast uses the script's last stdout line for that message. Leave **Show output** on for commands whose full logs you need to read; a run with an output window does not also show a confirmation.

Changing a script's `@raycast.mode` header or importing the folder again does not change settings on an already imported command. Edit that command in Tinycast. Failures are reported separately by Tinycast.

## Commands

- **Start Containers**: choose a worktree. The primary action enables `sftp`; **Start with Queue** also enables `queue`.
- **Stop Containers**: choose a worktree. Both `sftp` and `queue` profiles are enabled for shutdown.

Tinycast shows a running indicator while Docker Compose works and displays its output after the command finishes. The output view shows the last 12 lines; **Copy Output** copies the full result.

The extension and the separate IDL script commands both call the stowed `idl-up` and `idl-down` helpers. IDL Up accepts `--build` in its third argument, for example `queue, --build`. The only Compose profiles are `sftp` and `queue`.
