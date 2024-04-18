#!/bin/sh

notice "Cloning repositories..."

DEVELOPER=$HOME/Developer
CODE=$DEVELOPER/code
SRC=$DEVELOPER/src

# Create a developer directory
mkdir -p $CODE
mkdir -p $SRC

# Personal
git clone git@github.com:ammonkc/dotfiles.git $SRC/dotfiles


# Work - ILT
git clone git@bitbucket.org:dev_iltech/ilt.git $CODE/allegro.test
