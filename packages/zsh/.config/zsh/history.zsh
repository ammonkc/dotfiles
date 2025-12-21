# history setup
HISTFILE=${ZSH_STATE_DIR}/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase

# Arrow key history navigation is handled by atuin (if installed)
# Fallback bindings for systems without atuin:
if (( ! $+commands[atuin] )); then
  bindkey '^[[A' history-search-backward
  bindkey '^[[B' history-search-forward
fi

# Allow multiple terminal sessions to all append to one zsh command history
setopt APPEND_HISTORY

# This options works with HIST_EXPIRE_DUPS_FIRST option
setopt SHARE_HISTORY

# Add comamnds as they are typed, don't wait until shell exit
setopt INC_APPEND_HISTORY

# Do not write commands starting with a space to history (useful for sensitive commands)
setopt HIST_IGNORE_SPACE

# Delete old duplicate entries when adding new ones (more aggressive than HIST_IGNORE_DUPS)
setopt HIST_IGNORE_ALL_DUPS

# Don't write duplicate entries to the history file
setopt HIST_SAVE_NO_DUPS

# Expire duplicate entries first when trimming history
setopt HIST_EXPIRE_DUPS_FIRST

# When searching history, skip duplicates already shown
setopt HIST_FIND_NO_DUPS

# Remove extra blanks from each command line being added to history
setopt HIST_REDUCE_BLANKS

# Include more information about when the command was executed, etc
setopt EXTENDED_HISTORY

# Verify history expansion
setopt HIST_VERIFY
