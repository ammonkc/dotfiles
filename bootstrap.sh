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

update() {
  local files=( $(ls -a) )
  excluded+=(".private_env")
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
        notice "Then, we install Vundle (https://github.com/gmarik/vundle)."
        git clone https://github.com/gmarik/vundle.git bundle/vundle
    fi

    if [ ! -f local.vimrc ]; then
      notice "Let's create a 'local.vimrc' file so you have some bundles by default."
      cat << EOF > 'local.vimrc'
" local.vimrc
let g:vimified_packages = ['general', 'fancy', 'css', 'js', 'os', 'html', 'coding', 'color']
EOF
    fi

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

Bundle 'tpope/vim-git'
Bundle 'airblade/vim-gitgutter'
Bundle 'vim-scripts/restore_view.vim'
" Bundle 'markwu/vim-laravel-snippets'
" Bundle 'mattn/webapi-vim'
" Bundle 'mattn/gist-vim'

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

      cd "$INSTALLDIR"

      notice "Installing vim bundles..."
      vim +BundleInstall +qall 2&>/dev/null
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
excluded=(. .. .DS_Store .git .gitignore .gitmodules .osx .brew .themes .vimified bootstrap.sh install-deps.sh README.md)


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

  # Backup
  notice "Backup up old files ($backupdir)"
  backup

  # Install
  notice "Updating"
  zsh_themes
  update
else
  # Clone Repo
  notice "Downloading"
  git clone --recursive https://github.com/ammonkc/dotfiles.git $HOME/.dotfiles

  pushd $HOME/.dotfiles

  # Backup
  notice "Backup up old files ($backupdir)"
  backup

  # Install
  notice "Installing"
  zsh_themes
  install
  vimify
  notice "Don't forget to set your API Keys in $HOME/.private_env"
fi


#-----------------------------------------------------------------------------
# Finished
#-----------------------------------------------------------------------------

popd
notice "Done"
exec $SHELL -l
