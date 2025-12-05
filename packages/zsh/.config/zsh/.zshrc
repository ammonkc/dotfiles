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
fi

# Init mise with caching
if (( $+commands[mise] )); then
  cached-eval mise 'mise activate zsh --quiet'
fi

# Init zoxide with caching
if (( $+commands[zoxide] )); then
  cached-eval zoxide 'zoxide init --cmd cd zsh'
fi

# Init atuin with caching
if (( $+commands[atuin] )); then
  cached-eval atuin 'atuin init zsh'
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
# ---- Local config -----
# -----------------------
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local || true
