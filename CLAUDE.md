# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [Taskfile](https://taskfile.dev/). Configs live in `packages/*/` and are symlinked to `$HOME` following XDG standards (most configs end up in `~/.config/`).

## Task Runner

All operations use `task` (Taskfile v3). The main entry point is `taskfile.dist.yml`, which includes domain-specific taskfiles from `taskfiles/`.

```bash
task --list              # List all tasks
task install             # Full system setup (stow + mise + nvim plugins)
task doctor              # Run health checks
task info                # Show environment info
task clean               # Clean caches and old backups
```

The `dotfiles` (alias `dot`) and `dev` namespaces are available globally via the `dotfiles`/`dot` shell commands after installation.

## Key Commands

```bash
# Dotfile management
task dot:install         # Stow all packages + copy .local templates
task dot:restow PACKAGE=zsh  # Restow a specific package
task dot:uninstall       # Remove all symlinks
task dot:doctor          # Check symlink integrity

# Package managers
task brew:update         # Update Homebrew
task mise:install        # Install mise-managed runtimes
task mise:update         # Update runtimes
task mise:list           # List installed tools

# Neovim
task nvim:restore        # Restore plugins to lazy-lock.json state (idempotent)
task nvim:update         # Update plugins + commit lazy-lock.json
task nvim:check          # Run :checkhealth

# Shell
task shell:yazi:install  # Install yazi plugins from package.toml
task shell:clear_cache   # Clear zsh caches

# Git
task git:status          # Git status of dotfiles repo
task git:pull            # Pull with rebase
task git:sync            # Pull + restow
task git:push            # Push changes

# Secrets (requires 1Password CLI)
task secrets:install     # Pull secrets from 1Password
task system:post-install # Post-install setup (requires op signin)
```

## Architecture

### Package Structure

Each directory under `packages/` is a stow package. Stow symlinks its contents into `$HOME`, so:
- `packages/zsh/.config/zsh/` → `~/.config/zsh/`
- `packages/nvim/.config/nvim/` → `~/.config/nvim/`
- `packages/git/.config/git/` → `~/.config/git/`

The `--no-folding` flag ensures individual files are symlinked (not whole directories).

### Local Config Files

Files named `*.local` or `*.local.*` inside packages are **templates** — they are copied (not symlinked) to `$HOME` as `~/.filename` on first install and are not tracked in git. Key local files:
- `~/.zshenv.local` — private env vars
- `~/.zshrc.local` — personal zsh config
- `~/.gitconfig.local` — git identity (name, email, signing)
- `~/.env.local` — API keys and tokens
- `~/.tmux.local.conf` — local tmux config
- `~/.ssh/config` — SSH host configuration

### Zsh Config

Zsh uses [Zim](https://zimfw.sh/) as the framework. Config files under `packages/zsh/.config/zsh/`:
- `path.zsh` — PATH setup
- `exports.zsh` — environment exports
- `aliases.zsh` — shell aliases
- `functions/` — autoloaded functions
- `history.zsh`, `setopt.zsh`, `zstyle.zsh` — shell behavior

### Neovim

Based on [LazyVim](https://lazyvim.org/) with `lazy.nvim`. Plugin versions are locked in `packages/nvim/.config/nvim/lazy-lock.json`. Updates via `task nvim:update` automatically commit the lockfile.

### mise

Runtime version manager for Node, Python, Go, etc. Config at `packages/mise/.config/mise/config.toml`. Local overrides in `~/.config/mise/conf.d/` (not tracked).

### Taskfile Namespaces

| Namespace | File | Purpose |
|-----------|------|---------|
| `dot` | `dotfiles.yml` | Stow operations |
| `brew` | `brew.yml` | Homebrew |
| `mise` | `mise.yml` | Runtime manager |
| `nvim` | `nvim.yml` | Neovim plugins |
| `shell` | `shell.yml` | Zsh/yazi |
| `git` | `git.yml` | Dotfiles repo git ops |
| `secrets` | `secrets.yml` | 1Password secrets |
| `mac` | `mac.yml` | macOS preferences |
| `system` | `system.yml` | Full system setup |
| `dev` | `develop.yml` | Dev directory management |

### 1Password Integration

`task secrets:install` and `task dev:setup` read from 1Password. Required items:
- `id_ed25519` (SSH Key) — signing and auth
- `github` (Login with `username` and `token` fields)

Optional documents: `.gitconfig.local`, `.env.local`, `ssh_config.local`

## Commit Style

Commit messages follow conventional commits: `type(scope): description`
Common types: `chore`, `fix`, `feat`. Scope matches the affected package (e.g., `nvim`, `zsh`, `git`).
