# NOTE: .zshenv needs to live at ~/.zshenv, not in $ZDOTDIR!

# Set XDG base paths if you want to re-home Zsh.
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_BIN_DIR=${XDG_BIN_DIR:-$HOME/.local/bin}
export XDG_PROJECTS_DIR=${XDG_PROJECTS_DIR:-$HOME/Projects}
# zsh directories
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
export ZSH_CACHE_DIR=${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}
export ZSH_DATA_DIR=${ZSH_DATA_DIR:-$XDG_DATA_HOME/zsh}
export ZSH_STATE_DIR=${ZSH_STATE_DIR:-$XDG_STATE_HOME/zsh}
# dotfiles directories
export DOTFILES=${DOTFILES:-$HOME/.dotfiles}
export DOTFILES_PKG_DIR=${DOTFILES_PKG_DIR:-$DOTFILES/packages}
export DOTFILES_ZDIR=${DOTFILES_ZDIR:-$DOTFILES_PKG_DIR/zsh}
# composer
export COMPOSER_HOME=${COMPOSER_HOME:-$XDG_CONFIG_HOME/composer}
export COMPOSER_CACHE_DIR=${COMPOSER_CACHE_DIR:-$XDG_CACHE_HOME/composer}
export COMPOSER_BIN_DIR=${COMPOSER_BIN_DIR:-$XDG_BIN_DIR/composer}

# source PATH
[[ -e $ZDOTDIR/path.zsh ]] && source $ZDOTDIR/path.zsh

export SHORT_HOST="${HOST/.*/}"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-${SHORT_HOST}-${ZSH_VERSION}"

# Make sure directories exist
mkdir -p "$(dirname $ZSH_CACHE_DIR)"
mkdir -p "$(dirname $ZSH_DATA_DIR)"
mkdir -p "$(dirname $ZSH_STATE_DIR)"
mkdir -p "$(dirname $ZSH_COMPDUMP)"

# Local config
[[ -f $HOME/.zshenv.local ]] && source $HOME/.zshenv.local
