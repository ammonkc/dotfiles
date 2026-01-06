# ----------------------------
# ---- Core setup ------------
# ----------------------------
if (( $+commands[brew] )); then
  # If you're using macOS, you'll want this enabled
  eval "$(brew shellenv)"
fi

# ----------------------------
#  - zimfw zsh plugin manager
# ----------------------------
# Tell zim where to put the dump file
zstyle ':zim:completion' dumpfile "$ZSH_COMPDUMP"
zstyle ':zim:input' double-dot-expand yes
zstyle ':zim:git-info' verbose 'yes'

ZIM_HOME=${XDG_DATA_HOME:-${HOME}/.local/share}/zim
ZIM_CONFIG_FILE=${XDG_CONFIG_HOME:-${HOME}/.config}/zimrc
# Install missing modules and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE} ]]; then
  source ${HOMEBREW_PREFIX}/opt/zimfw/share/zimfw.zsh init
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

# ----------------------------
# ---- Setup vi Mode ---------
# ----------------------------
bindkey -v

# ----------------------------
# ---- Source config files ---
# ----------------------------
[[ -e $ZDOTDIR/history.zsh ]] && source $ZDOTDIR/history.zsh
[[ -e $ZDOTDIR/setopt.zsh ]] && source $ZDOTDIR/setopt.zsh
[[ -e $ZDOTDIR/zstyle.zsh ]] && source $ZDOTDIR/zstyle.zsh
[[ -e $ZDOTDIR/aliases.zsh ]] && source $ZDOTDIR/aliases.zsh
[[ -e $ZDOTDIR/fzf.zsh ]] && source $ZDOTDIR/fzf.zsh
[[ -e $ZDOTDIR/eza.zsh ]] && source $ZDOTDIR/eza.zsh

# ----------------------------
# --- functions autoload -----
# ----------------------------
typeset -U fpath
fpath+=($ZDOTDIR/functions)               # Add custom functions directory to fpath
autoload -Uz $ZDOTDIR/functions/*(:tX)

# ----------------------------
# Interactive shell integrations
# ----------------------------

# Init oh-my-posh prompt with caching
if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && (( $+commands[oh-my-posh] )); then
  # Allow theme override via OHMYPOSH_THEME environment variable
  # Set in ~/.zshenv.local to customize locally
  local ohmyposh_theme="${OHMYPOSH_THEME:-$XDG_CONFIG_HOME/oh-my-posh/themes/p10k-rainbow.omp.toml}"

  #eval "$(oh-my-posh init zsh --config $ohmyposh_theme)"
  cached-eval oh-my-posh "oh-my-posh init zsh --config $ohmyposh_theme"

  # Override oh-my-posh's empty set_poshcontext stub with our custom function
  # This must happen AFTER oh-my-posh init (the cached init defines an empty stub)
  autoload +X set_poshcontext
fi

# Init mise with caching
if (( $+commands[mise] )); then
  cached-eval mise 'mise activate zsh --quiet'
fi

# Init zoxide with caching
# Override the command alias via ZOXIDE_CMD env var (default: cd)
if (( $+commands[zoxide] )); then
  cached-eval zoxide "zoxide init --cmd ${ZOXIDE_CMD:-cd} zsh"
fi

# Init atuin (disable default up-arrow binding, we'll set it manually after all plugins load)
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# Init thefuck with caching
if (( $+commands[thefuck] )); then
  cached-eval thefuck 'thefuck --alias'
  alias fk='fuck'  # shorter alias
fi

# -----------------------
# ---- FastFetch -----
# -----------------------
[[ -e $ZDOTDIR/fastfetch.zsh ]] && source $ZDOTDIR/fastfetch.zsh || true

# -----------------------
# ---- Keybinding fixes -----
# -----------------------
# Re-bind atuin keys (zimfw history-substring-search overrides them)
if (( $+commands[atuin] )); then
  # Emacs mode
  bindkey -M emacs '^[[A' atuin-up-search
  bindkey -M emacs '^[OA' atuin-up-search
  bindkey -M emacs '^r' atuin-search
  # Vi insert mode
  bindkey -M viins '^[[A' atuin-up-search-viins
  bindkey -M viins '^[OA' atuin-up-search-viins
  bindkey -M viins '^r' atuin-search-viins
  # Vi command mode
  bindkey -M vicmd '^[[A' atuin-up-search-vicmd
  bindkey -M vicmd '^[OA' atuin-up-search-vicmd
  bindkey -M vicmd '/' atuin-search-vicmd
  bindkey -M vicmd 'k' atuin-up-search-vicmd
fi

# -----------------------
# ---- Local config -----
# -----------------------
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local || true
