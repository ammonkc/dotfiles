# Developer Utilities for Tinycast and Raycast

This Raycast API extension is shared by both launchers. The Raycast path
`packages/raycast/extensions/developer-utilities` links to this source tree,
so command and test changes apply to both.

- **Clean Node Modules** scans the configured Projects Directory, shows disk use and package dates, lets you select directories, and confirms before deletion. It never follows symlinked directories during the scan and rechecks each selected directory before deletion.
- **Git Standup** lists Git repositories under the same Projects Directory, then shows your commits from the last day or three days, or everyone's commits from the last day. It calls the stowed `~/.local/bin/git-standup` command.
- **Open Worktree** lists Git checkouts under the Projects Directory, including linked worktrees, and opens the selected folder in Zed. Set the Editor Application preference to another macOS app name if you prefer a different editor.
- **GenAI AWS SSO** checks whether the configured AWS CLI profile already has usable credentials. If its SSO session expired, AWS CLI opens the default browser for sign-in; the command verifies credentials afterward. The AWS SSO Profile preference defaults to `genai`. A browser sign-in alone does not create an AWS CLI session.

The default Projects Directory is `~/Developer`. Change it in extension preferences if your projects live elsewhere. The scanner searches up to eight levels deep and skips dependency and build directories. Repository discovery searches up to six levels deep.

## Tinycast

After the repo has been deployed to `~/.dotfiles`, run
`dotfiles dot:tinycast:utilities`. In Tinycast Settings > Extensions, choose
**Add from folder** and select the printed `build` directory. Build output
stays in the checkout where the task ran and is not stowed into the source
directory.

## Raycast

Run `dotfiles dot:raycast:utilities` from the deployed checkout, or
`task dot:raycast:utilities` from the development checkout. This installs
dependencies and starts Raycast development mode. Keep that task running while
using the local extension. Run IDL Docker's Raycast development task in a
separate terminal if you want both extensions active.

The older `genai-login.sh` script command remains available in both launchers
as a fallback. Disable it in a launcher if you prefer a single GenAI login
command.
