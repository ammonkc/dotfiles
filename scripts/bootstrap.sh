#!/bin/bash

set -e

# Color helper functions
info() { echo -e "\033[0;34m⚙️  $1\033[0m"; }
success() { echo -e "\033[0;32m✓ $1\033[0m"; }
error() { echo -e "\033[0;31m❌ $1\033[0m"; }
warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ammonkc/dotfiles.git}"

if [[ ! -d $DOTFILES_DIR ]]; then
  info "Cloning dotfiles repository..."
  git clone $DOTFILES_REPO --branch main --single-branch $DOTFILES_DIR || {
    error "Failed to clone dotfiles"
    exit 1
  }
  success "Dotfiles cloned successfully"
else
  success "Dotfiles already exist"
  cd "$DOTFILES_DIR"
  git pull origin main
fi

info "Running dotfiles installation..."
cd "$DOTFILES_DIR" || exit 1

./bin/install
