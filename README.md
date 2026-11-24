# Dotfiles

<p align="center">
  <img src="art/dotfiles-logo.png" alt="Dotfiles">
</p>

> 🚀 Automated development environment setup for macOS (and Linux) using GNU Stow and Taskfile

Personal dotfiles and automated setup scripts for Apple Silicon Macs with secondary Linux support. Bootstrap installs the base environment; 1Password configuration follows after sign-in.

## ✨ Features

- 🏡 **XDG Compliant** - Clean home directory with configs in `~/.config/`
- ⚡ **Taskfile Automation** - Modern task runner for all operations
- 🎨 **Enhanced Shell** - Zsh + Zim + Oh My Posh + modern CLI tools
- 🔧 **Resumable Setup** - Install the base environment, then finish secrets after sign-in
- 🔄 **Idempotent & Safe** - Run multiple times without issues
- 📦 **Version Controlled** - Core tool versions pinned via mise; Neovim plugins locked

## 🚀 Quick Start

### **macOS**

**Prerequisites:**
- An Apple Silicon Mac, running a native arm64 shell, with a macOS release supported by current Homebrew and the packages in this Brewfile
- Administrator access (you'll be prompted for your password several times during the installation process)

**Step 1: Install Xcode Command Line Tools**

```bash
xcode-select --install
```

Wait for the installation to complete (you may need to accept a license agreement).

**Step 2: Run Bootstrap Script**

```bash
curl -fsSL https://raw.githubusercontent.com/ammonkc/dotfiles/main/scripts/bootstrap.sh | bash
```

For a smaller first install, use `DOTFILES_PROFILE=core` with a local checkout (`DOTFILES_PROFILE=core ./bin/install`), or export the variable before running the bootstrap command. The default `full` profile installs the core package set first, then the full Brewfile. A failure in the optional full bundle is recorded and can be retried with `task brew:retry`.

After bootstrap, sign in with `op signin`, run `dotfiles system:post-install`, then check `dotfiles system:status`. The status command is safe to rerun and lists remaining work.
For an interactive menu of secondary setup steps on macOS, run `dotfiles system:guided-setup` in a terminal. Gum is included in the full Brewfile; after a core install, run `brew install gum` first. The menu is optional and does not run during bootstrap.

### **Linux** (Debian/Ubuntu or Arch)

Linux support is experimental. Helper scripts, Stow, and configuration have automated coverage, but a full installation has not been validated end to end and there is no Linux CI install job. Expect rough edges.

Run `dotfiles linux:install` to install packages from the Linuxfile, then `dotfiles linux:doctor` to check the result.

For development, run `task lint` and `task test` in this checkout. See
[Automated testing](docs/testing.md) for dependencies, focused suites, and extension checks.

**What gets installed:**
- Homebrew (macOS) or native package managers (Linux)
- GNU Stow, Neovim, Git, and modern CLI tools (the login shell stays the system `/bin/zsh`)
- Development runtimes via [mise](https://mise.jdx.dev/) (Node, Python, and other configured tools)
- Optional: macOS apps via Cask, custom system preferences

**Duration:** Depends on network speed, full bundle size, and app installation prompts.

## 📂 dotfiles Project Structure

```
~/.dotfiles/
├── packages/         # Stowed configs (zsh, nvim, git, tmux, etc.)
├── taskfiles/        # Task definitions by domain
├── scripts/          # Bootstrap & automation
├── Brewfile          # Full Homebrew packages
├── Brewfile.core     # Core Homebrew packages
└── taskfile.dist.yml # Main task orchestration
```

GNU Stow creates symlinks from `packages/*/` to your home directory following XDG standards.

**Result:** Most tool configs live under `~/.config/`, `~/.local/`, and `~/.cache/`; local secrets and shell entry files remain in `~/`.

## 💡 Usage

After installation, you can manage your dotfiles from anywhere using the `dotfiles` command or `dot` alias:

### **Global Commands**

```bash
update                      # Update dotfiles repo system packages and tools
dotfiles --list             # List all available tasks (from anywhere)
dotfiles doctor             # Run system health checks
dotfiles clean              # Clean caches and old backups
dotfiles info               # Show environment information
```

### **Common Tasks**

```bash
# Dotfile Management
dotfiles install            # Install base tools, link dotfiles, restore Neovim plugins
dotfiles dot:list           # List available packages
dotfiles dot:restow PACKAGE=zsh   # Re-stow one package
dotfiles dot:plan            # Preview Stow links and conflicts without changing files (run from ~/.dotfiles; a dev checkout reports conflicts)
dotfiles dot:verify          # Compare development and deployed commits; check managed links
dotfiles system:check        # Strict, read-only core installation check

# Package Management
dotfiles brew:upgrade       # Update Homebrew and upgrade installed packages (macOS)
dotfiles brew:update        # Regenerate the Brewfile from installed packages and commit it (macOS)
dotfiles mise:update        # Update development tools
dotfiles nvim:update        # Update Neovim plugins

# macOS Specific
dotfiles mac:set:defaults   # Apply macOS preferences
dotfiles mac:preview:shortcuts  # Preview the optional Cmd+Space shortcut change
dotfiles mac:set:shortcuts  # Tinycast on Cmd+Space, Spotlight on Ctrl+Space (optional)
dotfiles mac:op:setup       # Setup 1Password SSH agent

# Development
dotfiles dev:setup          # Setup development directories
dotfiles dev:list           # List development projects
dotfiles dev:clone REPO=url # Clone repo to organized location
# Tinycast extension builds require Node.js 22.22.2 or newer.
dotfiles dot:tinycast:extensions # Build all Tinycast extensions for import
dotfiles dot:tinycast:window-edges # Build size-preserving edge movements (macOS)
dotfiles dot:raycast:extension   # Run Raycast IDL Docker (keep task running)
dotfiles dot:raycast:utilities   # Run Developer Utilities in Raycast (keep running)

# Git Operations
dotfiles git:status         # Git status of dotfiles repo
dotfiles git:pull           # Pull latest changes
dotfiles git:push           # Push changes
dotfiles dev:status         # Show dirty repositories and worktrees under ~/Developer
dotfiles dev:handoff        # Print a Markdown summary of the current worktree

# Utilities
dotfiles backup:list        # List backups
dotfiles clean:all          # Clean system caches
dotfiles info:all           # Show detailed system info
```

Run the two Raycast extension tasks in separate terminals if you use both.

Development directories created by `dotfiles dev:setup` are
`~/Developer/{code,documentation,repos,scripts,worktrees}`. The `scripts/`
directory is for your own scripts; the dotfiles command wrappers remain under
`~/.local/bin`.

`git-worktree-setup` delegates to Worktrunk's `wt step copy-ignored --require-include`.
Select ignored files with gitignore-style patterns in the primary checkout's
local `.worktreeinclude` (for example, `.env`, `vendor/`, and `node_modules/`).
Existing destination files are kept; without an include file, nothing is copied.
On APFS, Worktrunk uses copy-on-write clones where supported. Use
`git-worktree-setup -n` to preview copying. Both the Zed creation hook and the
Worktrunk user hook call this helper. `.worktree-copy` and `--all` are retired;
non-ignored untracked files are no longer copied by automatic setup.

Agent worktrees use the same layout through `agent-worktree`. After deploying and
stowing the bin, claude, codex, opencode, and worktrunk packages, run
`dotfiles dot:agents:worktrees` to install OpenCode's strategy from the primary
claude-fiyah checkout (`opencode/worktrunk/`) and merge
Claude and OpenCode's worktree settings. Existing settings are preserved and
private backups are created. Restart those tools afterward. Claude's isolation
hook and OpenCode's native worktree strategy use Worktrunk; Codex's global
AGENTS.md directs agent-created worktrees through the same helper. Codex's native
managed-worktree UI is not overridden. Orca's parent directory is configured in
its app settings.

From a project worktree, `dotfiles dev:handoff` prints a Markdown handoff.
Set `SUMMARY`, `CHECKS`, and `NEXT` to record details the Git history cannot
provide, or `REPO` to select another worktree. For example:

```bash
dotfiles dev:handoff SUMMARY='Implemented feature' CHECKS='task test passed' NEXT='Review PR' > /tmp/worktree-handoff.md
```

## 🎨 Customization

**Local config files** (not tracked in git):
- `~/.env.local` - Private env exports, api keys, tokens
- `~/.zshrc.local` - Personal Zsh config
- `~/.zshenv.local` - Personal Zsh env config
- `~/.gitconfig.local` - Git name, email, signing
- `~/.tmux.local.conf` - Local tmux config
- `~/.config/mise/conf.d/` - Local tool versions

## 📋 Post-Installation

1. **Check progress:** `dotfiles system:status`
2. **Restart terminal:** `exec $SHELL`
3. **[Optional] Apply macOS preferences:** Review `scripts/macos.sh`, then `dotfiles mac:set:defaults`
   To put Tinycast on Cmd+Space, preview and then run `dotfiles mac:set:shortcuts`. It moves Spotlight to Ctrl+Space and input source switching to Ctrl+Shift+Space. Quit Tinycast first, and log out and back in if the old shortcuts remain. These settings use undocumented formats, so recheck them after a macOS or Tinycast update.
4. **Sign In to 1Password**
    - **Enable Touch ID:** Settings > Security and turn on Touch ID
    - **Enable CLI integration:** Developer > Settings and select "Integrate with 1Password CLI"
    - **Check the CLI sees your account:** `op account list` should print your account. With the integration on you do not need `op signin`.
    - **Run** `dotfiles system:post-install`
    - **If `op` says "No accounts configured for use with 1Password CLI"** although the integration is on, run `op --debug account list 2>&1 | head -40`. A line such as `read file: open .../Group Containers/2BUA8C4S2C.com.1password/.../settings.json: operation not permitted` means macOS is blocking your terminal from reading 1Password's data. Add the terminal app under System Settings > Privacy & Security > Full Disk Access, quit and reopen it, then run `op account list` again. This was confirmed on macOS 27.2.1 with Ghostty. If it still fails, run `op account add` and then `eval "$(op signin)"` in the same terminal.
5. **[Optional] Enable 1Password SSH agent:** In 1Password, Settings → Developer → Enable SSH agent; then run `dotfiles mac:op:setup`. Run `dotfiles mac:github:force_ssh` if GitHub HTTPS URLs should use SSH.
6. **[Optional] Set up work accounts:** Sign into the business accounts in 1Password, then run `dotfiles system:work-setup`.
   You can use `dotfiles system:guided-setup` to choose these optional steps from a terminal menu.
7. **Customize local configs:** Edit files in `~/.*.local`
8. **Setup Developer folders:** Included in `dotfiles system:post-install`

**Quick verification:**
```bash
dotfiles --list             # Should show all available tasks
update                      # Should update all packages
dotfiles info               # Should show system information
```

## 🔐 1Password Item Naming Conventions

The `secrets:install` and `dev:setup` tasks read from 1Password using specific item names. Ensure these items exist for full automation.

### Personal Account (Required)

| Item Name | Type | Fields | Purpose |
|-----------|------|--------|---------|
| `id_ed25519` | SSH Key | `public key` | Git commit signing, GitHub SSH auth |
| `github` | Login | `username`, `token` | Git config, GitHub API access |

### Personal Account (Optional Documents)

| Document Name | Purpose |
|---------------|---------|
| `.gitconfig.local` | Additional git config (appended to `~/.gitconfig.local`) |
| `.env.local` | Environment variables (appended to `~/.env.local`) |
| `ssh_config.local` | SSH host configs (appended to `~/.ssh/config`) |

### Work/Business Accounts

For each business 1Password account, the following items enable work-specific configs:

| Item Name | Type | Fields | Purpose |
|-----------|------|--------|---------|
| `id_ed25519` | SSH Key | `public key` | Git commit signing for work repos |

**What gets created:**
- `~/.gitconfig.<company>.local` — Work-specific git user/email (company name extracted from your email domain)
- `~/Developer/repos/<company>/` — Work project directory
- `[includeIf]` directive in `~/.gitconfig.local` for automatic identity switching

### Creating Items in 1Password

**SSH Key (`id_ed25519`):**
1. Create new SSH Key item named `id_ed25519`
2. The `public key` field is auto-generated

**GitHub Login (`github`):**
1. Create new Login item named `github`
2. Add `username` field with your GitHub username
3. Add `token` field with a GitHub Personal Access Token

**Documents (`.gitconfig.local`, etc.):**
1. Create a new Document
2. Name it exactly as shown (including the leading dot)
3. Upload a text file with your config content

### Syncing Keys to GitHub

After creating 1Password items, sync your SSH keys to GitHub:

```bash
dotfiles secrets:gh-keys      # Sync personal SSH keys
dotfiles secrets:work-keys    # Sync work SSH keys
dotfiles secrets:all-keys     # Sync all keys
```

This adds your keys for both authentication and commit signing.

## 🐛 Troubleshooting

**Bootstrap fails:**
```bash
xcode-select --install  # macOS: Install Xcode CLI Tools
```
**Neovim issues:**
```bash
task nvim:check    # Check for issues
task nvim:restore  # Reinstall plugins
```

## 🛠️ Tech Stack

- [GNU Stow](https://www.gnu.org/software/stow/) - Dotfile symlink manager
- [Taskfile](https://taskfile.dev/) - Task runner
- [Homebrew](https://brew.sh/) - Package manager (macOS)
- [mise](https://mise.jdx.dev/) - Runtime manager
- [Zim](https://zimfw.sh/) - Zsh framework
- [Neovim](https://neovim.io/) + [lazy.nvim](https://github.com/folke/lazy.nvim)

## 📝 License

MIT License - see [LICENSE.md](LICENSE.md)

## 🙏 Credits

Inspired by [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles), [holman/dotfiles](https://github.com/holman/dotfiles), and [dotfiles.github.io](https://dotfiles.github.io/)

---

<p align="center">
  <strong>⭐ If you found this helpful, consider giving it a star!</strong>
</p>
