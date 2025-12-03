# sourced by zshenv

function _path_add() {
  case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="$1${PATH+:$PATH}" ;;
  esac
  export PATH
}

function _path_remove() {
  case ":$PATH:" in
    *:"$1":*)
      if command -v sd >/dev/null 2>&1; then
        PATH=$(echo ":$PATH:" | sd ":$1:" ":" | sd '^:' '' | sd ':$' '')
      else
        PATH=$(echo ":$PATH:" | sed "s|:$1:|:|g" | sed 's/^://' | sed 's/:$//')
      fi
      ;;
  esac
  export PATH
}

function _ensure_first_path() {
  _path_remove $1
  _path_add $1
}

# homebrew
if [[ -z $HOMEBREW_PREFIX ]]; then
  case $(uname) in
  Darwin)
    if [[ $(uname -m) == 'arm64' ]]; then
      HOMEBREW_PREFIX='/opt/homebrew'
    elif [[ $(uname -m) == 'x86_64' ]]; then
      HOMEBREW_PREFIX='/usr/local'
    fi
    ;;
  Linux)
    if [[ -d '/home/linuxbrew/.linuxbrew' ]]; then
      HOMEBREW_PREFIX='/home/linuxbrew/.linuxbrew'
    elif [[ -d $HOME/.linuxbrew ]]; then
      HOMEBREW_PREFIX=$HOME/.linuxbrew
    fi
    ;;
  esac
fi
if [[ -d $HOMEBREW_PREFIX ]]; then
  export BREW_DATA_HOME="$HOMEBREW_PREFIX/share"
fi

# Ensure path arrays do not contain duplicates.
typeset -gaU path
# Set the list of directories that zsh searches for commands.
path=(
  $XDG_BIN_DIR
  /usr/local/{,s}bin(N)
  node_modules/.bin(N)
  vendor/bin(N)
  $COMPOSER_BIN_DIR/vendor/bin
  $path
)

# NOTE: LinkedIn machine image puts `/opt/homebrew/bin/` on path via
# `/etc/paths.d/`, but it is in the wrong location (it ends up having it's
# binaries like `delta` shadowed), so we remove and prepend it
# _ensure_first_path "$HOMEBREW_PREFIX/bin"
# _ensure_first_path "$HOMEBREW_PREFIX/sbin"
# _ensure_first_path "/opt/homebrew/opt/fzf/bin"
# _ensure_first_path "$XDG_BIN_DIR"


# This is handled by the zimfw module
# zmodule joke/zim-mise
# if (( $+commands[mise] )); then
#   # mise is available
#   eval "$(mise activate zsh)"
# fi
