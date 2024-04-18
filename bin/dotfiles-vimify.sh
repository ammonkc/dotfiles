#!/bin/sh

# Sync dotfiles repo and ensure that dotfiles are tangled correctly afterward

info "Installing vimify"

# Navigate to the directory of this script (generally ~/.dotfiles/.bin)
cd $(dirname $(readlink -f $0))
cd ..

if [ -d "$DOTFILES/vimified" ]; then
    if [ -d $HOME/.vim ] && [ ! -L $HOME/.vim ]; then
        [ -d "$HOME/.vim" ] && rm -rf "$HOME/.vim"
    fi

    if [ -f $HOME/.vimrc ] && [ ! -L $HOME/.vimrc ]; then
        [ -f "$HOME/.vimrc" ] && rm -rf "$HOME/.vimrc"
    fi

    if [ ! -f ~/.vim ]; then
        notice "Now, we will create ~/.vim and ~/.vimrc files to configure Vim."
        ln -sfn "$DOTFILES/vimified" "$HOME/.vim"
    fi

    if [ ! -f ~/.vimrc ]; then
        ln -sfn "$DOTFILES/vimified/vimrc" "$HOME/.vimrc"
    fi

    cd "$DOTFILES/vimified"

    if [ ! -d "bundle" ]; then
        notice "Now, we will create a separate directory to store the bundles Vim will use."
        mkdir bundle
        mkdir -p tmp/backup tmp/swap tmp/undo
    fi

    if [ ! -d "bundle/vundle" ]; then
        notice "Then, we install Vundle https://github.com/gmarik/vundle"
        git clone https://github.com/gmarik/vundle.git bundle/vundle
    fi

    VIMRCS=($DOTFILES/stubs/*.vimrc)
    VIMRCS=("${VIMRCS[@]##*/}")
    for VIMRC in "${VIMRCS[@]}"; do
        cp "$DOTFILES/stubs/$VIMRC" "$DOTFILES/vimified/$VIMRC"
    done

    notice "Installing vim bundles..."
    vim +BundleInstall +qall 2&>/dev/null
fi
