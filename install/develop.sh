#!/bin/sh

notice "Setting up your development environment..."
echo
notice "Install pecl extentions"
echo

# Install PHP extensions with PECL
pecl install imagick

# Clone Github repositories
source $DOTFILES/install/clone.sh
