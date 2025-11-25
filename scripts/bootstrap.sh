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

# Check for git
if ! command -v git >/dev/null 2>&1; then
  error "Git is not installed"
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  warning "Please run this script again after Xcode Command Line Tools installation completes"
  warning "You may need to accept the license agreement in a popup window"
  exit 1
fi

if [[ ! -d $DOTFILES_DIR ]]; then
  info "Cloning dotfiles repository..."
  git clone $DOTFILES_REPO --branch $DOTFILES_BRANCH --single-branch $DOTFILES_DIR || {
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
  git pull origin $DOTFILES_BRANCH

  # Inform about stash but don't auto-pop (safer)
  if git stash list | grep -q "Auto-stash before bootstrap"; then
    echo ""
    info "Note: Stashed changes can be restored with: git stash pop"
    info "Or review with: git stash list"
  fi
fi

info "Running dotfiles installation..."
cd "$DOTFILES_DIR" || exit 1

./bin/install
