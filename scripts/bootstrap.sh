#!/bin/bash

set -e

# Color helper functions
info() { echo -e "\033[0;34m⚙️  $1\033[0m"; }
success() { echo -e "\033[0;32m✓ $1\033[0m"; }
error() { echo -e "\033[0;31m❌ $1\033[0m"; }
warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ammonkc/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# Check if running in non-interactive mode (piped from curl)
if [ ! -t 0 ]; then
  export NONINTERACTIVE=1
  info "Running in non-interactive mode (NONINTERACTIVE=1)"
fi

# Preflight checks
info "Running preflight checks..."
if [[ "$OSTYPE" == "darwin"* && "$(uname -m)" != "arm64" ]]; then
  error "This macOS bootstrap supports Apple Silicon in a native arm64 shell only."
  exit 1
fi

# Request sudo access upfront (needed for Homebrew installation)
if [[ "$OSTYPE" == "darwin"* ]]; then
  info "Requesting sudo access for Homebrew installation..."
  # Redirect to /dev/tty to allow password prompt when piped from curl
  if ! sudo -v < /dev/tty; then
    error "Sudo access is required for Homebrew installation"
    error "Please ensure your user has administrator privileges"
    exit 1
  fi

  # Keep sudo alive in the background
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# Check the protocol this bootstrap actually uses; ICMP may be blocked.
if ! curl -fsSIL --retry 2 --connect-timeout 5 --max-time 20 https://github.com >/dev/null; then
  error "GitHub is not reachable over HTTPS"
  error "Please check your network connection and try again"
  exit 1
fi

# Full installs include a large optional app bundle; core installs need less space.
DOTFILES_PROFILE="${DOTFILES_PROFILE:-full}"
case "$DOTFILES_PROFILE" in
  full) MIN_SPACE_GB=20 ;;
  core) MIN_SPACE_GB=5 ;;
  *) error "DOTFILES_PROFILE must be core or full"; exit 1 ;;
esac
export DOTFILES_PROFILE

# Check available disk space.
if [[ "$OSTYPE" == "darwin"* ]]; then
  AVAILABLE_SPACE=$(df -g "$HOME" | tail -1 | awk '{print $4}')
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  AVAILABLE_SPACE=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | sed 's/G//')
else
  AVAILABLE_SPACE=999  # Skip check on unknown OS
fi

if [[ "$AVAILABLE_SPACE" -lt "$MIN_SPACE_GB" ]]; then
  warning "Low disk space detected (${AVAILABLE_SPACE}GB available)"
  warning "The $DOTFILES_PROFILE profile recommends at least ${MIN_SPACE_GB}GB free"
  if [[ -z "${NONINTERACTIVE:-}" ]]; then
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    warning "Continuing anyway in non-interactive mode..."
  fi
fi

success "Preflight checks passed"
echo ""

# Check for Xcode Command Line Tools on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    error "Xcode Command Line Tools are not installed"
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    warning "Please run this script again after Xcode Command Line Tools installation completes"
    warning "You may need to accept the license agreement in a popup window"
    exit 1
  fi
fi

# Check for git
if ! command -v git >/dev/null 2>&1; then
  error "Git is not installed"

  # Detect OS and install git accordingly
  if [[ "$OSTYPE" == "darwin"* ]]; then
    error "Git should be available after installing Xcode Command Line Tools"
    info "Try running: xcode-select --install"
    exit 1
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    info "Installing git..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y git
      success "Git installed successfully"
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --needed --noconfirm git
      success "Git installed successfully"
    else
      error "Unsupported package manager"
      error "Please install git manually and run this script again"
      exit 1
    fi
  else
    error "Unsupported operating system: $OSTYPE"
    error "Please install git manually and run this script again"
    exit 1
  fi
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
  info "Cloning dotfiles repository..."
  git clone "$DOTFILES_REPO" --branch "$DOTFILES_BRANCH" --single-branch "$DOTFILES_DIR" || {
    error "Failed to clone dotfiles"
    exit 1
  }
  success "Dotfiles cloned successfully"
else
  success "Dotfiles already exist at $DOTFILES_DIR"
  cd "$DOTFILES_DIR"

  # Stash any local changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    warning "Local changes detected - auto-stashing for safety"
    git stash push -m "Auto-stash before bootstrap pull $(date +%Y-%m-%d-%H%M%S)"
    info "Your changes are saved in: git stash list"
  fi

  # Pull latest changes
  info "Updating from remote..."
  git pull origin "$DOTFILES_BRANCH"

  # Inform about stash but don't auto-pop (safer)
  if git stash list | grep -q "Auto-stash before bootstrap"; then
    echo ""
    info "Note: Stashed changes can be restored with: git stash pop"
    info "Or review with: git stash list"
  fi
fi

info "Running dotfiles installation..."
cd "$DOTFILES_DIR" || exit 1

# Ensure install script is executable
chmod +x ./bin/install

./bin/install
