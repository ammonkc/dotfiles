# sourced by zshenv

function _ensure_first_path() {
  [[ -n $1 ]] || return
  path=("$1" $path)
  export PATH
}

# homebrew
if [[ -z $HOMEBREW_PREFIX ]]; then
  case $(uname) in
  Darwin)
    HOMEBREW_PREFIX='/opt/homebrew'
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
if [[ -n $HOMEBREW_PREFIX ]]; then
  _ensure_first_path "$HOMEBREW_PREFIX/bin"
  _ensure_first_path "$HOMEBREW_PREFIX/sbin"
fi
[[ -d /opt/homebrew/opt/fzf/bin ]] && _ensure_first_path "/opt/homebrew/opt/fzf/bin"
_ensure_first_path "$XDG_BIN_DIR"


# This is handled by the zimfw module
# zmodule joke/zim-mise
# if (( $+commands[mise] )); then
#   # mise is available
#   eval "$(mise activate zsh)"
# fi
