# Dotfiles

<p align="center">
  <img src="art/dotfiles-logo.png" alt="Dotfiles">
</p>

> 🚀 Automated development environment setup for macOS (and Linux) using GNU Stow and Taskfile

Personal dotfiles and automated setup scripts for macOS with secondary Linux support. Get from zero to fully configured in one command.

## ✨ Features

- 🏡 **XDG Compliant** - Clean home directory with configs in `~/.config/`
- ⚡ **Taskfile Automation** - Modern task runner for all operations
- 🎨 **Enhanced Shell** - Zsh + Zim + Oh My Posh + modern CLI tools
- 🔧 **One-Command Setup** - Fresh machine to fully configured in ~20 minutes
- 🔄 **Idempotent & Safe** - Run multiple times without issues
- 📦 **Version Controlled** - Tool versions locked via mise and Neovim

## 🚀 Quick Start

### **macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/ammonkc/dotfiles/main/scripts/bootstrap.sh | bash
```

**Prerequisites:**
- macOS 11+
- Administrator access (you'll be prompted for your password for Homebrew installation)

**Note:** The script will request sudo access at the beginning for Homebrew installation.

### **Linux** (Debian/Ubuntu or Arch)

Same command as above.

**Prerequisites:**
- Sudo access (you'll be prompted for your password during package installation)

**What gets installed:**
- Homebrew (macOS) or native package managers (Linux)
- GNU Stow, Zsh, Neovim, Git, modern CLI tools
- Development runtimes via [mise](https://mise.jdx.dev/) (Node, Python, Go, etc.)
- Optional: macOS apps via Cask, custom system preferences

**Duration:** 15-30 minutes

## 📂 Structure

```
~/.dotfiles/
├── packages/         # Stowed configs (zsh, nvim, git, tmux, etc.)
├── taskfiles/        # Task definitions by domain
├── scripts/          # Bootstrap & automation
├── Brewfile          # Homebrew packages
└── taskfile.dist.yml # Main task orchestration
```

**How it works:** GNU Stow creates symlinks from `packages/*/` to your home directory following XDG standards.

**Result:** Only `.zshenv` in `~/` - everything else in `~/.config/`, `~/.local/`, `~/.cache/`

## 💡 Usage

After installation, you can manage your dotfiles from anywhere using the `dotfiles` command or `dot` alias:

### **Global Commands**

```bash
dotfiles --list             # List all available tasks (from anywhere)
dotfiles doctor             # Run system health checks
dotfiles clean              # Clean caches and old backups
dotfiles info               # Show environment information
update                      # Update system packages and tools
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

# Git Operations
dotfiles git:status         # Git status of dotfiles repo
dotfiles git:pull           # Pull latest changes
dotfiles git:push           # Push changes

# Utilities
dotfiles backup:list        # List backups
dotfiles clean:all          # Clean system caches
dotfiles info:all           # Show detailed system info
```

**How it works:**
- `dotfiles` is a wrapper script in `~/.local/bin/` that runs `task -d ~/.dotfiles`
- `dot` is a shell alias (shortcut for `dotfiles`)
- `update` is a wrapper script that runs `task system:update`
- All commands work from any directory without needing to `cd ~/.dotfiles`

## 🎨 Customization

**Local config files** (not tracked in git):
- `~/.config/git/config.local` - Git name, email, signing
- `~/.config/zsh/.zshrc.local` - Personal Zsh config
- `~/.config/mise/.mise.local.toml` - Local tool versions

**After Bootstrap - Enable SSH for Git:**

The bootstrap process uses HTTPS for git operations. Once your SSH keys are set up (via 1Password SSH agent or `ssh-keygen`), you can switch to SSH by removing these lines from `~/.config/git/config.local`:

```ini
[url "https://github.com/"]
  insteadOf = git@github.com:
```

After removing those lines, git will use SSH (faster, more secure) for all GitHub operations.

**Add new dotfiles:**
```bash
mkdir -p packages/myapp/.config/myapp
echo "config" > packages/myapp/.config/myapp/config.yml
cd packages && stow --target ~/ myapp
```

## 📋 Post-Installation

1. **Restart terminal:** `exec $SHELL`
2. **Verify installation:** `dotfiles --list` (should show all tasks)
3. **[Optional] Apply macOS preferences:** Review `scripts/macos.sh`, then `dotfiles mac:set:defaults`
4. **[Optional] Enable 1Password SSH:** Settings → Developer → Enable SSH agent, then `dotfiles mac:op:setup`
5. **Customize local configs:** Edit files in `~/.config/*/config.local`

**Quick verification:**
```bash
dotfiles --list             # Should show all available tasks
update                      # Should update all packages
dotfiles info               # Should show system information
```

## 🐛 Troubleshooting

**Bootstrap fails:**
```bash
xcode-select --install  # macOS: Install Xcode CLI Tools
```

**Homebrew not in PATH:**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel
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
