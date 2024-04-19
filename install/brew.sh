#!/bin/sh

# Check for Homebrew and install if we don't have it
if ! command -v brew &> /dev/null; then
    notice "Installing homebrew..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'eval "$($(which brew) shellenv)"' >> $HOME/.zprofile
    eval "$($(which brew) shellenv)"
fi

notice "Brew all the things"

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file $DOTFILES/install/Brewfile
