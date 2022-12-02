#!/bin/sh

echo "Cloning repositories..."

DEVELOP=$HOME/Develop
SITES=$Develop/Sites
SRC=$Develop/src

# Personal
git clone git@github.com:ammonkc/dotfiles.git $SRC/dotfiles
