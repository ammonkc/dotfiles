# -----------------------
# --- setup fzf theme ---
# -----------------------
# Override via FZF_THEME env var in exports.zsh or ~/.env.local
# Available: catppuccin-mocha (default), night-owl, tokyonight, dracula, nord

# Define theme color palettes
case "${FZF_THEME:-catppuccin-mocha}" in
  catppuccin-mocha)
    fg="#cdd6f4"
    bg="#1e1e2e"
    bg_highlight="#313244"
    purple="#cba6f7"
    blue="#89b4fa"
    cyan="#94e2d5"
    ;;
  tokyonight)
    fg="#c0caf5"
    bg="#1a1b26"
    bg_highlight="#292e42"
    purple="#bb9af7"
    blue="#7aa2f7"
    cyan="#7dcfff"
    ;;
  dracula)
    fg="#f8f8f2"
    bg="#282a36"
    bg_highlight="#44475a"
    purple="#bd93f9"
    blue="#8be9fd"
    cyan="#50fa7b"
    ;;
  nord)
    fg="#eceff4"
    bg="#2e3440"
    bg_highlight="#3b4252"
    purple="#b48ead"
    blue="#81a1c1"
    cyan="#88c0d0"
    ;;
  night-owl)
    fg="#CBE0F0"
    bg="#011628"
    bg_highlight="#143652"
    purple="#B388FF"
    blue="#06BCE4"
    cyan="#2CF9ED"
    ;;
  *)
    # Default: catppuccin-mocha
    fg="#cdd6f4"
    bg="#1e1e2e"
    bg_highlight="#313244"
    purple="#cba6f7"
    blue="#89b4fa"
    cyan="#94e2d5"
    ;;
esac

# add support for Ansi for fd color
export FZF_DEFAULT_OPTS="--ansi"

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --margin 0,0 \
  --color=fg:${fg},bg:${bg},hl:${purple} \
  --color=fg+:${fg},bg+:${bg_highlight},hl+:${purple} \
  --color=info:${blue},prompt:${cyan},pointer:${cyan} \
  --color=marker:${cyan},spinner:${cyan},header:${cyan}"

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# fzf-git
[[ -e $ZIM_HOME/modules/fzf-git.sh/fzf-git.sh ]] && source $ZIM_HOME/modules/fzf-git.sh/fzf-git.sh || true
