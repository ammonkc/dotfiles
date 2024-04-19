#!/bin/sh

# Sync dotfiles repo and ensure that dotfiles are tangled correctly afterward
notice "Syncing dotfiles repo"

# Navigate to the directory of this script (generally ~/.dotfiles/.bin)
notice "dir: $(dirname $(readlink -f $0))"
pushd $DOTFILES

notice "Stashing existing changes..."

stash_result=$(git stash push -m "sync-dotfiles: Before syncing dotfiles")
needs_pop=1
if [ "$stash_result" = "No local changes to save" ]; then
    needs_pop=0
fi

notice "Pulling updates from dotfiles repo..."
echo
git pull origin stow
git submodule init
git submodule update --remote --merge
echo

if [[ $needs_pop -eq 1 ]]; then
    notice "Popping stashed changes..."
    echo
    git stash pop
fi

unmerged_files=$(git diff --name-only --diff-filter=U)
if [[ ! -z $unmerged_files ]]; then
    error "The following files have merge conflicts after popping the stash:"
    echo
    printf %"s\n" $unmerged_files  # Ensure newlines are printed
fi
