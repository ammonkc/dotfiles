# Dotfiles

<p align="center">
  <img src="art/dotfiles-logo.png" alt="Dotfiles">
</p>

> 🚀 Automated development environment setup for macOS (and Linux) using GNU Stow and Taskfile

This repository contains my personal dotfiles and automated setup scripts for macOS, with secondary support for Linux (Debian/Ubuntu and Arch). It's designed to get a fresh Mac from zero to fully configured development environment with a single command.

---

## 🎯 What This Does

This dotfiles setup will:

1. **Install Essential Tools**
   - Homebrew package manager
   - Command-line utilities (git, zsh, neovim, etc.)
   - Development tools via [mise](https://mise.jdx.dev/)
   - macOS applications via Homebrew Cask

2. **Configure Your Environment**
   - Symlink dotfiles to your home directory using [GNU Stow](https://www.gnu.org/software/stow/)
   - Set up Zsh with [Zim](https://zimfw.sh/) framework
   - Configure Neovim with plugins (managed by [lazy.nvim](https://github.com/folke/lazy.nvim))
   - Set up development tools (git, tmux, lazygit, etc.)

3. **Provide Optional Customizations**
   - macOS system preferences (Finder, Dock, keyboard, etc.)
   - 1Password SSH agent integration
   - Local configuration overrides

---

## ✨ Key Features

- 🏡 **XDG Base Directory Compliant** - Clean home directory with configs in `~/.config/`
- ⚡ **Taskfile Automation** - Modern task runner for all operations
- 🎨 **Enhanced Shell** - Zsh + Zim + Oh My Posh + modern CLI tools
- 🔧 **One-Command Setup** - Fresh Mac to fully configured in ~20 minutes
- 🔄 **Idempotent & Safe** - Run multiple times without breaking anything
- 📦 **Version Controlled** - All tool versions locked via mise and Neovim lock file
- 🍎 **macOS Optimized** - Curated system preferences for productivity

---

## 🏡 Clean Home Directory (XDG Base Directory)

These dotfiles try to be compliant with [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) to keep your home directory clean and organized:

```bash
~/.config/           # Configuration files (XDG_CONFIG_HOME)
~/.local/bin/        # User executables
~/.local/share/      # User data files (XDG_DATA_HOME)
~/.local/state/      # User state files (XDG_STATE_HOME)
~/.cache/            # Cache files (XDG_CACHE_HOME)
```

**What this means:**
- ✅ **Clean Home `~/`** - No dotfile clutter
- ✅ All configs in `~/.config/` (Zsh, Git, Neovim, etc.)
- ✅ Scripts in `~/.local/bin/` instead of `~/bin`
- ✅ Data files organized in `~/.local/share/`
- ✅ Backups stored in `~/.local/share/dotfiles/backups/`
- ✅ Consistent structure across all tools

---

## 📦 What Gets Installed

### **Core Tools**
- **Homebrew** - Package manager for macOS
- **GNU Stow** - Symlink farm manager for dotfiles
- **Zsh** - Modern shell with Zim framework
- **Neovim** - Extensible text editor
- **Git** - Version control
- **Taskfile** - Task runner (replaces Makefile)

### **Development Tools** (via mise)
- Node.js, Python, Go, Rust, etc.
- Configurable in `packages/mise/.config/mise/config.toml`

### **Modern CLI Utilities**
- `bat` - Better `cat` with syntax highlighting
- `fd` - Better `find` command
- `ripgrep` - Better `grep` command
- `fzf` - Fuzzy finder
- `eza` - Better `ls` command
- `lazygit` - Terminal UI for git
- `tmux` - Terminal multiplexer
- `gh` - GitHub CLI
- And more! (see [Brewfile](./Brewfile))

### **Applications** (optional, see Brewfile)
- 1Password
- Visual Studio Code
- Docker
- And more...

---

## 🚀 Quick Start

### **Prerequisites**

#### **macOS**
- macOS (tested on Sequoia 15.x, works on Big Sur 11.x+)
- Xcode Command Line Tools (installed automatically if missing)
- Admin access (for Homebrew and some system tools)

#### **Linux** (Debian/Ubuntu or Arch)
- Debian/Ubuntu (tested on Ubuntu 22.04+) or Arch Linux
- Git (installed automatically if missing, requires sudo)
- Sudo access (**you'll be prompted for password during package installation**)

### **Fresh macOS Setup**

On a brand new Mac, run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/ammonkc/dotfiles/main/scripts/bootstrap.sh | bash
```

**What happens:**
1. Checks for and installs Xcode Command Line Tools (if needed)
2. Clones this repository to `~/.dotfiles` (customizable via `$DOTFILES_DIR`)
3. Installs Taskfile (task runner)
4. Runs the main installation tasks

**Duration:** ~15-30 minutes depending on internet speed

### **Fresh Linux Setup (Debian/Ubuntu or Arch)**

On a fresh Linux system:

**What happens:**
1. Checks for and installs git (if needed, requires sudo)
2. Clones this repository to `~/.dotfiles` (customizable via `$DOTFILES_DIR`)
3. Installs Taskfile and mise
4. Installs packages from `Linuxfile.debian` or `Linuxfile.arch`
5. Installs modern CLI tools (eza, lazygit, yazi, etc.)
6. Sets up dotfiles and development environment

**Duration:** ~20-40 minutes depending on internet speed and system

**Note:** Linux support is a WIP

---

## 📂 Project Structure

```
dotfiles/
├── packages/           # Stow packages (dotfiles organized by tool)
│   ├── zsh/           # Zsh configuration
│   ├── nvim/          # Neovim configuration
│   ├── git/           # Git configuration
│   ├── tmux/          # Tmux configuration
│   ├── mise/          # Development tool versions
│   └── ...            # Other tool configurations
├── scripts/           # Automation scripts
│   ├── bootstrap.sh   # Main bootstrap script
│   └── macos.sh       # macOS system preferences
├── taskfiles/         # Task definitions (organized by domain)
│   ├── dotfiles.yml   # Dotfile management (stow)
│   ├── brew.yml       # Homebrew management
│   ├── mise.yml       # Development tool management
│   ├── nvim.yml       # Neovim setup
│   ├── mac.yml        # macOS preferences
│   └── ...
├── bin/               # Custom scripts and utilities
│   └── install        # Main installation entry point
├── Brewfile           # Homebrew packages and apps
└── taskfile.dist.yml  # Main task orchestration
```

### **How Stow Works**

Each package in `packages/` mirrors your home directory structure. Since we follow XDG standards, most configs go in `.config/`:

```
packages/zsh/
├── .zshenv             → ~/.zshenv (ONLY file in ~/)
└── .config/
    └── zsh/
        ├── .zshrc      → ~/.config/zsh/.zshrc
        ├── .zprofile   → ~/.config/zsh/.zprofile
        └── ...

packages/git/
└── .config/
    └── git/
        ├── config      → ~/.config/git/config
        ├── ignore      → ~/.config/git/ignore
        └── ...

packages/nvim/
└── .config/
    └── nvim/           → ~/.config/nvim/
        ├── init.lua
        └── ...

packages/bin/
└── .local/
    └── bin/            → ~/.local/bin/
        └── (scripts)
```

When you run `task dot:install`, Stow creates symlinks from your home directory to the files in packages.

**Key point:** `.zshenv` is the ONLY dotfile in your home directory root. It sets `$ZDOTDIR` to `~/.config/zsh/`, which tells Zsh to load all other configs from there.

### **XDG Directory Structure**

Following XDG standards strictly, your home directory stays clean:

```
~/
└── .zshenv            # ONLY dotfile in home directory!

~/.config/             # All configuration files
├── zsh/               # Zsh configs (via $ZDOTDIR)
│   ├── .zshrc
│   ├── .zprofile
│   ├── aliases.zsh
│   └── ...
├── git/               # Git config (via $XDG_CONFIG_HOME)
│   ├── config
│   ├── ignore
│   └── ...
├── nvim/              # Neovim configuration
│   ├── init.lua
│   ├── lua/
│   └── ...
├── mise/              # Development tool versions
│   └── config.toml
├── lazygit/           # Lazygit configuration
├── gh/                # GitHub CLI config
├── atuin/             # Shell history sync
└── ...                # Other tool configs

~/.local/
├── bin/               # User scripts and executables
│   ├── task           # Taskfile runner
│   └── ...            # Other tools
├── share/
│   ├── dotfiles/
│   │   └── backups/   # Dotfile conflict backups
│   ├── nvim/          # Neovim data (plugins, state)
│   └── zsh/           # Zsh data files
├── state/
│   └── zsh/           # Zsh state files
└── ...

~/.cache/              # Cache files
└── zsh/               # Zsh cache
```

**Result:** Your home directory (`~/`) only contains `.zshenv` - everything else is organized in XDG directories!

---

## 🔧 Available Commands

After installation, use `task` to manage your dotfiles:

### **Core Commands**

```bash
task --list              # Show all available tasks
task install             # Full system setup (run on fresh machine)
task dot:install         # Install/update dotfiles only
```

### **Package Management**

```bash
task brew:install        # Install Homebrew packages
task brew:update         # Update Brewfile from current system
task mise:install        # Install development tools
task mise:update         # Update development tools
```

### **Neovim**

```bash
task nvim:restore        # Restore Neovim plugins from lazy-lock.json
task nvim:update         # Update Neovim plugins
task nvim:check          # Run Neovim health checks
```

### **macOS Preferences** (Optional)

```bash
task mac:set:defaults    # Apply macOS system preferences
task mac:restart:dock    # Restart Dock
task mac:restart:finder  # Restart Finder
task mac:sync            # Apply preferences and restart apps
```

### **Backups**

```bash
task backup:list         # List all dotfile backups
task backup:restore      # Restore from a backup
task backup:clean        # Remove old backups
```

---

## 🎨 Customization

### **Local Overrides**

The following local files are created but **not tracked** in git, allowing personal customization:

- `~/.config/git/config.local` - Personal git config (name, email, signing keys)
- `~/.config/zsh/.zshrc.local` - Personal Zsh configuration
- `~/.config/mise/.mise.local.toml` - Local tool versions

These files are sourced automatically and won't be overwritten by updates.

### **Adding New Dotfiles**

1. Create a new package in `packages/`:
   ```bash
   mkdir -p packages/myapp/.config/myapp
   ```

2. Add your config files (mirroring home directory structure):
   ```bash
   echo "config content" > packages/myapp/.config/myapp/config.yml
   ```

3. Stow the package:
   ```bash
   cd packages && stow --target ~/ myapp
   ```

### **Modifying macOS Preferences**

Review and edit `scripts/macos.sh` before applying:

```bash
# Review what will change
cat scripts/macos.sh

# Apply when ready
task mac:set:defaults
```

---

## 🔄 Keeping Up to Date

### **Update Everything**

```bash
cd ~/.dotfiles  # Or your custom $DOTFILES_DIR location
git pull
task install
```

### **Update Specific Components**

```bash
task brew:update         # Update Homebrew packages
task mise:update         # Update development tools
task nvim:update         # Update Neovim plugins
task dot:install         # Re-stow dotfiles (after changes)
```

---

## 📋 Post-Installation Steps

After the bootstrap completes, you'll see next steps:

### **1. Restart Your Terminal**

```bash
exec $SHELL
```

### **2. [Optional] Apply macOS Preferences**

```bash
# Review first
cat scripts/macos.sh

# Apply when ready
task mac:set:defaults
```

This will configure:
- Fast keyboard key repeat
- Finder preferences (show extensions, path bar)
- Dock behavior (auto-hide, no recent apps)
- And more...

### **3. [Optional] Enable 1Password SSH Agent**

1. Open 1Password → Settings → Developer
2. Enable "Use the SSH agent"
3. Run: `task mac:op:setup`

### **4. Customize Local Configs**

Edit these files with your personal settings:

```bash
# Personal git config (not tracked)
vim ~/.config/git/config.local

# Personal Zsh config (not tracked)
vim ~/.config/zsh/.zshrc.local
```

**Local override files:**
- `~/.config/git/config.local` - Git name, email, signing keys
- `~/.config/zsh/.zshrc.local` - Personal Zsh aliases and functions
- `~/.config/mise/.mise.local.toml` - Local tool versions

---

## 🛠️ Technology Stack

- **[GNU Stow](https://www.gnu.org/software/stow/)** - Symlink farm manager for dotfiles
- **[Taskfile](https://taskfile.dev/)** - Modern task runner (Make alternative)
- **[Homebrew](https://brew.sh/)** - macOS package manager
- **[mise](https://mise.jdx.dev/)** - Polyglot runtime manager (asdf alternative)
- **[Zim](https://zimfw.sh/)** - Blazing fast Zsh framework
- **[Neovim](https://neovim.io/)** - Hyperextensible Vim-based text editor
- **[lazy.nvim](https://github.com/folke/lazy.nvim)** - Modern plugin manager for Neovim

---

## 🔍 Under the Hood

### **Bootstrap Flow**

The bootstrap process follows these steps:

1. **Check for Git** → Install Xcode CLI Tools if needed
2. **Clone Repository** → To `~/.dotfiles` (or custom location)
3. **Install Taskfile** → Modern task runner
4. **Run `task install`**:
   - Install Homebrew and packages
   - Stow all dotfile packages
   - Install mise-managed tools
   - Restore Neovim plugins
5. **Show Next Steps** → Guide for optional setup

### **Idempotency**

All tasks are idempotent - safe to run multiple times:
- ✅ Skips already installed tools
- ✅ Backs up conflicting files before overwriting
- ✅ Updates existing configurations
- ✅ No destructive operations

### **Conflict Handling**

When stowing dotfiles, if a file already exists:
1. It's backed up to `~/.local/share/dotfiles/backups/TIMESTAMP/`
2. The original is removed
3. A symlink is created

You can restore backups with: `task backup:restore`

---

## 🐛 Troubleshooting

### **Bootstrap fails with "command not found"**

Make sure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

### **Homebrew not in PATH**

Restart your terminal or run:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

### **Neovim plugins not loading**

```bash
task nvim:check         # Check for issues
task nvim:restore       # Reinstall plugins
```

### **Stow conflicts**

If stow complains about existing files:
```bash
task backup:list        # Check existing backups
rm ~/.conflicting-file  # Remove manually if needed
task dot:install        # Try again
```

---

## 🤝 Contributing

This is a personal dotfiles repository, but feel free to:
- Fork it and adapt to your needs
- Open issues for bugs
- Suggest improvements via pull requests

---

## 📚 Learn More

- [Building Your Own Dotfiles](https://dotfiles.github.io/)
- [GNU Stow Documentation](https://www.gnu.org/software/stow/manual/)
- [Taskfile Documentation](https://taskfile.dev/)
- [mise Documentation](https://mise.jdx.dev/)

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE.md).

---

## 🙏 Acknowledgments

Inspired by and borrowed ideas from:
- [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [GitHub does dotfiles](https://dotfiles.github.io/)

---

<p align="center">
  <strong>⭐ If you found this helpful, consider giving it a star!</strong>
</p>
