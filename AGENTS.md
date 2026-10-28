# Dotfiles project guidance

Work on dotfiles in `~/Developer/repos/ammonkc/dotfiles`. Commit and push there,
then it is deployed to `~/.dotfiles` via update script and tasks. Stow links home configs from the
deployed checkout. Do not edit `~/.dotfiles` as a substitute for development.

## Structure

- `packages/<name>/` contains a Stow package. Its files map into `$HOME`.
- `taskfile.dist.yml` includes the task definitions in `taskfiles/`.
- `scripts/` contains bootstrap and task helpers. `tests/` contains isolated checks.
- Files such as `~/.env.local`, `~/.gitconfig.local`, and `~/.ssh/config` may
  contain secrets. Keep their real values out of this repository and test output.
- Apple Silicon is the supported macOS architecture. Work setup and macOS
  preferences are optional. Atuin manages shell history.

## Working on changes

- Use `task --list` to find an existing task before adding one.
- For Stow changes, run `task dot:plan` or use an isolated target directory.
- Run focused tests for the changed behavior. CI checks shell syntax, task
  loading, Stow behavior, and extension builds.
- Do not run bootstrap, `brew bundle`, Stow against the real home directory,
  or macOS preferences just to validate a code change.
- `git-worktree-setup` copies only paths listed in a project's `.worktree-copy`
  by default. `--all` opts into copying all ignored and untracked files.
- Use `task dev:handoff` to summarize a worktree before passing it to another
  agent. Record checks and next steps explicitly.

Use conventional commit messages such as `fix(zsh): correct path setup`.
