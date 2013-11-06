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
notice() { printf  "\033[1;32m=> $1\033[0m"; }

# Error title
error() { printf "\033[1;31m=> Error: $1\033[0m"; }

# List item
c_list() { printf  "  \033[1;32m✔\033[0m $1"; }

# Error list item
e_list() { printf  "  \033[1;31m✖\033[0m $1"; }

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

backup() {
  mkdir -p $backupdir

  local files=( $(ls -a) )
  for file in "${files[@]}"; do
    in_array $file "${excluded[@]}" || cp -Rf "$HOME/$file" "$backupdir/$file"
  done
}

install() {
  local files=( $(ls -a) )
  for file in "${files[@]}"; do
    in_array $file "${excluded[@]}"
    should_install=$?
    if [ $should_install -gt 0 ]; then
      [ -d "$HOME/$file" ] && rm -rf "$HOME/$file"
      cp -Rf "$file" "$HOME/$file"
    fi
  done
}

vimify() {
  INSTALLDIR="$HOME/.dotfiles"
  if [ -d "$INSTALLDIR/.vimified" ]; then
    if [ -d $HOME/.vim ] && [ ! -L $HOME/.vim ]; then
      cp -Rf "$HOME/.vim" "$backupdir/.vim"
      [ -d "$HOME/.vim" ] && rm -rf "$HOME/.vim"
    fi
    if [ -f $HOME/.vimrc ] && [ ! -L $HOME/.vimrc ]; then
      cp -Rf "$HOME/.vimrc" "$backupdir/.vimrc"
      [ -f "$HOME/.vimrc" ] && rm -rf "$HOME/.vimrc"
    fi

    if [ ! -f ~/.vim ]; then
        echo "Now, we will create ~/.vim and ~/.vimrc files to configure Vim."
        ln -sfn "$INSTALLDIR/.vimified" "$HOME/.vim"
    fi

    if [ ! -f ~/.vimrc ]; then
        ln -sfn "$INSTALLDIR/.vimified/vimrc" "$HOME/.vimrc"
    fi

    cd "$INSTALLDIR/.vimified"

    if [ ! -d "bundle" ]; then
      echo "Now, we will create a separate directory to store the bundles Vim will use."
      mkdir bundle
      mkdir -p tmp/backup tmp/swap tmp/undo
    fi

    if [ ! -d "bundle/vundle" ]; then
        echo "Then, we install Vundle (https://github.com/gmarik/vundle)."
        git clone https://github.com/gmarik/vundle.git bundle/vundle
    fi

    if [ ! -f local.vimrc ]; then
      echo "Let's create a 'local.vimrc' file so you have some bundles by default."
      echo "let g:vimified_packages = ['general', 'fancy', 'css', 'js', 'os', 'html', 'coding', 'color']" > 'local.vimrc'
      echo 'if &term == "xterm-ipad"' >> 'local.vimrc'
      echo 'nnoremap <Tab> <Esc>' >> 'local.vimrc'
      echo 'vnoremap <Tab> <Esc>gV' >> 'local.vimrc'
      echo 'onoremap <Tab> <Esc>' >> 'local.vimrc'
      echo 'inoremap <Tab> <Esc>`^' >> 'local.vimrc'
      echo 'inoremap <Leader><Tab> <Tab>' >> 'local.vimrc'
      echo 'endif' >> 'local.vimrc'
    fi

    cd "$INSTALLDIR"
  fi
}

zsh_themes() {
  local themes=( $(ls .themes) )
  for theme in "${themes[@]}"; do
      cp -Rf ".themes/$theme" ".oh-my-zsh/themes/$theme"
  done
}

in_array() {
  local hay needle=$1
  shift
  for hay; do
    [[ $hay == $needle ]] && return 0
  done
  return 1
}

#-----------------------------------------------------------------------------
# Initialize
#-----------------------------------------------------------------------------

backupdir="$HOME/.dotfiles-backup/$(date "+%Y%m%d%H%M.%S")"
dependencies=(git tree vim)
excluded=(. .. .git .gitignore .gitmodules .osx .brew .themes .vimified bootstrap.sh install-deps.sh README.md)


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
  notice "Updating"
  git pull origin master
  git submodule init
  git submodule update

  # Backup
  notice "Backup up old files ($backupdir)"
  backup

  # Install
  notice "Installing"
  zsh_themes
  install
else
  # Clone Repo
  notice "Downloading"
  git clone --recursive git@github.com:ammonkc/dotfiles.git $HOME/.dotfiles

  pushd $HOME/.dotfiles

  # Backup
  notice "Backup up old files ($backupdir)"
  backup

  # Install
  notice "Installing"
  zsh_themes
  install
  vimify
  vim +BundleInstall +qall 2>/dev/null
fi


#-----------------------------------------------------------------------------
# Finished
#-----------------------------------------------------------------------------

popd
notice "Done"
exec $SHELL -l

