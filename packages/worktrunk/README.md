# Worktrunk

New worktrees live in `~/Developer/worktrees/<remote-repo>/<sanitized-branch>`.
Removal keeps branches. Existing worktrees remain in their current locations.

The global `pre-start` hook runs `git-worktree-setup` before startup.
The helper delegates to `wt step copy-ignored --require-include`. Copying is a
no-op without a `.worktreeinclude` in the primary checkout.
On APFS, Worktrunk uses copy-on-write clones when supported. Only ignored files
matching the include patterns copy; existing destination files are skipped.

Keep this file local to each repository (the Git package globally ignores it):

```gitignore
# .worktreeinclude
.env
vendor/
node_modules/
```

IDL also runs `idl-worktree-setup` automatically when Worktrunk creates a worktree.
Install the bin package for the shared setup helper and the zed package for the
IDL task template. Zed creation hooks and Worktrunk both call the same setup
helper. `.worktree-copy` and the setup helper's `--all` option are retired; migrate
ignored-file selections to `.worktreeinclude`. Non-ignored untracked files are
not part of automatic setup. The standalone copy utilities remain available for
manual use.

Zed tasks can create a branch (prompting for its name), list worktrees, or choose
and open an existing worktree. Opening uses the `zed` CLI and does not depend on
shell directory-switching integration. Worktrunk-created IDL worktrees get their
IDL task template through the user hook; Zed-created worktrees can use the manual
“setup IDL worktree tasks” task.

Deploy with the usual update and Stow tasks. For example:

```sh
git -C "$HOME/.dotfiles" pull --ff-only origin main
dotfiles dot:restow PACKAGE=bin
dotfiles dot:restow PACKAGE=git
dotfiles dot:restow PACKAGE=worktrunk
dotfiles dot:restow PACKAGE=zed
```
