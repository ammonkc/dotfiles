#!/bin/bash

#-----------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------

# xterm colors
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

# Notice title
notice() { printf  "\033[1;32m=> $1\033[0m \n"; }

# Error title
error() { printf "\033[1;31m=> Error: $1\033[0m \n"; }

# List item
c_list() { printf  "  \033[1;32m✔\033[0m $1 \n"; }

# Error list item
e_list() { printf  "  \033[1;31m✖\033[0m $1 \n"; }

# Check for dependency
dep() {
  type -p $1 &> /dev/null
  local installed=$?
  if [ $installed -eq 0 ]; then
    c_list $1
  else
    e_list $1
  fi
  return $installed
}

vimify() {
  INSTALLDIR="$HOME/.dotfiles"
  if [ -d "$INSTALLDIR/.vimified" ]; then
    if [ -d $HOME/.vim ] && [ ! -L $HOME/.vim ]; then
      [ -d "$HOME/.vim" ] && rm -rf "$HOME/.vim"
    fi
    if [ -f $HOME/.vimrc ] && [ ! -L $HOME/.vimrc ]; then
      [ -f "$HOME/.vimrc" ] && rm -rf "$HOME/.vimrc"
    fi

    if [ ! -f ~/.vim ]; then
        notice "Now, we will create ~/.vim and ~/.vimrc files to configure Vim."
        ln -sfn "$INSTALLDIR/.vimified" "$HOME/.vim"
    fi

    if [ ! -f ~/.vimrc ]; then
        ln -sfn "$INSTALLDIR/.vimified/vimrc" "$HOME/.vimrc"
    fi

    cd "$INSTALLDIR/.vimified"

    if [ ! -d "bundle" ]; then
      notice "Now, we will create a separate directory to store the bundles Vim will use."
      mkdir bundle
      mkdir -p tmp/backup tmp/swap tmp/undo
    fi

    if [ ! -d "bundle/vundle" ]; then
        notice "Then, we install Vundle https://github.com/gmarik/vundle"
        git clone https://github.com/gmarik/vundle.git bundle/vundle
    fi

    if [ ! -f local.vimrc ]; then
      notice "Let's create a 'local.vimrc' file so you have some bundles by default."
      cat << EOF > 'local.vimrc'
" local.vimrc
let g:vimified_packages = ['general', 'fancy', 'os', 'color']
EOF
    fi

    cd "$INSTALLDIR"

    notice "Installing vim bundles..."
    vim +BundleInstall +qall 2&>/dev/null

    if [ ! -f before.vimrc ]; then
      notice "Creating'before.vimrc' file"
      cat << EOF > 'before.vimrc'
" before.vimrc
EOF
    fi

    if [ ! -f after.vimrc ]; then
      notice "Creating'after.vimrc' file"
      cat << EOF > 'after.vimrc'
" Colorscheme
syntax enable
set background=dark
colorscheme solarized

" restore_view.vim configs
set viewoptions=cursor,folds,slash,unix
" let g:skipview_files = ['*\.vim']

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

" unicode symbols
"let g:airline_left_sep = '»'
"let g:airline_left_sep = '▶'
"let g:airline_right_sep = '«'
"let g:airline_right_sep = '◀'
"let g:airline_symbols.linenr = '␊'
"let g:airline_symbols.linenr = '␤'
"let g:airline_symbols.linenr = '¶'
"let g:airline_symbols.branch = '⎇'
"let g:airline_symbols.paste = 'ρ'
"let g:airline_symbols.paste = 'Þ'
"let g:airline_symbols.paste = '∥'
"let g:airline_symbols.whitespace = 'Ξ'

" powerline symbols
"let g:airline_left_sep = ''
"let g:airline_left_alt_sep = ''
"let g:airline_right_sep = ''
"let g:airline_right_alt_sep = ''
"let g:airline_symbols.branch = ''
"let g:airline_symbols.readonly = ''
"let g:airline_symbols.linenr = ''

" old vim-powerline symbols
let g:airline_left_sep = '⮀'
let g:airline_left_alt_sep = '⮁'
let g:airline_right_sep = '⮂'
let g:airline_right_alt_sep = '⮃'
let g:airline_symbols.branch = '⭠'
let g:airline_symbols.readonly = '⭤'
let g:airline_symbols.linenr = '⭡'

" Map arrow keys
nmap <Left> <Left>
nmap <Right> <Right>
nmap <Up> <Up>
nmap <Down> <Down>

if &term == "xterm-ipad"
  nnoremap <Tab> <Esc>
  vnoremap <Tab> <Esc>gV
  onoremap <Tab> <Esc>
  inoremap <Tab> <Esc>\`^
  inoremap <Leader><Tab> <Tab>
endif
EOF
      fi
  fi
}

zsh_shell() {
  if [ ! -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    chsh -s /bin/zsh
  fi
}

#-----------------------------------------------------------------------------
# Initialize
#-----------------------------------------------------------------------------

dependencies=(git tree vim)

#-----------------------------------------------------------------------------
# Dependencies
#-----------------------------------------------------------------------------

notice "Checking dependencies"

not_met=0
for need in "${dependencies[@]}"; do
  dep $need
  met=$?
  not_met=$(echo "$not_met + $met" | bc)
done

if [ $not_met -gt 0 ]; then
  error "$not_met dependencies not met!"
  exit 1
fi


#-----------------------------------------------------------------------------
# Install
#-----------------------------------------------------------------------------

# Assumes $HOME/.dotfiles is *ours*
if [ -d $HOME/.dotfiles ]; then
  pushd $HOME/.dotfiles

  # Update Repo
  notice "Updating git repo"
  git pull origin master
  git submodule init
  git submodule update --remote

  # Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
  rm -rf $HOME/.zshrc
  ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc

else
  # Check for Oh My Zsh and install if we don't have it
  if test ! $(which omz); then
    # Clone Repo
    notice "Downloading"
    git clone --recursive https://github.com/ammonkc/dotfiles.git --branch master --single-branch $HOME/.dotfiles
  fi

  if [ -d $HOME/.dotfiles ]; then
    pushd $HOME/.dotfiles

    git submodule update --remote

    # Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
    rm -rf $HOME/.zshrc
    ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc

    # Install
    notice "Installing vimify"
    vimify

    # Setup a fresh mac
    # $HOME/.dotfiles/fresh.sh
    notice "Don't forget to set your API Keys in $HOME/.private_env"
  fi
fi


#-----------------------------------------------------------------------------
# Finished
#-----------------------------------------------------------------------------

popd
notice "Done"
exec $SHELL -l
