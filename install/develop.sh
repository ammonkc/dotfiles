#!/bin/sh

notice "Setting up your development environment..."
echo
notice "Install pecl extentions"
echo
# Install PHP extensions with PECL
printf "\n" | pecl install imagick

DEVELOPER=$HOME/Developer
mkdir -p $DEVELOPER/code
mkdir -p $DEVELOPER/src

# Clone Github repositories
# source $DOTFILES/install/clone.sh
