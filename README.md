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

### **Linux** (Debian/Ubuntu or Arch)

Should work, but is not really tested at this time.

**What gets installed:**
- Homebrew (macOS) or native package managers (Linux)
- GNU Stow, Zsh, Neovim, Git, modern CLI tools
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
dotfiles install            # Install/update dotfiles
dotfiles list               # List installed packages
dotfiles restow             # Re-stow all packages

# Package Management
dotfiles brew:update        # Update Homebrew packages (macOS)
dotfiles mise:update        # Update development tools
dotfiles nvim:update        # Update Neovim plugins

# macOS Specific
dotfiles mac:set:defaults   # Apply macOS preferences
dotfiles mac:op:setup       # Setup 1Password SSH agent

# Development
dotfiles dev:setup          # Setup development directories
dotfiles dev:list           # List development projects
dotfiles dev:clone REPO=url # Clone repo to organized location
dotfiles dot:tinycast:extensions # Build both Tinycast extensions for import

# Git Operations
dotfiles git:status         # Git status of dotfiles repo
dotfiles git:pull           # Pull latest changes
dotfiles git:push           # Push changes

# Utilities
dotfiles backup:list        # List backups
dotfiles clean:all          # Clean system caches
dotfiles info:all           # Show detailed system info
```

## 🎨 Customization

**Local config files** (not tracked in git):
- `~/.env.local` - Private env exports, api keys, tokens
- `~/.zshrc.local` - Personal Zsh config
- `~/.zshenv.local` - Personal Zsh env config
- `~/.gitconfig.local` - Git name, email, signing
- `~/.tmux.local.conf` - Local tumx config
- `~/.config/mise/conf.d/` - Local tool versions

## 📋 Post-Installation

1. **Check progress:** `dotfiles system:status`
2. **Restart terminal:** `exec $SHELL`
3. **[Optional] Apply macOS preferences:** Review `scripts/macos.sh`, then `dotfiles mac:set:defaults`
4. **Sign In to 1Password**
    - **Enable Touch ID:** Settings > Security and turn on Touch ID
    - **Enable CLI integration:** Developer > Settings and select "Integrate with 1Password CLI"
    - **Enable 1Password SSH:** Settings → Developer → Enable SSH agent
    - **Run** `dotfiles system:post-install` after `op signin`
5. **Setup 1Password Items:** Ensure items follow the naming conventions below
6. **Setup Secrets:** `dotfiles system:post-install` handles these; rerun it after interruptions
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
