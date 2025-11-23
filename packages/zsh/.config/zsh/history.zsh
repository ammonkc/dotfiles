# history setup
HISTFILE=${ZSH_STATE_DIR}/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Allow multiple terminal sessions to all append to one zsh command history
setopt APPEND_HISTORY

# This options works with HIST_EXPIRE_DUPS_FIRST option
setopt SHARE_HISTORY

# Add comamnds as they are typed, don't wait until shell exit
setopt INC_APPEND_HISTORY

# Do not write events to history that are duplicates of previous events
setopt HIST_IGNORE_SPACE

# Do not store duplications
setopt HIST_IGNORE_ALL_DUPS

# When searching history don't display results already cycled through twice
setopt HIST_SAVE_NO_DUPS

# Expire duplicate entries first when trimming history
setopt HIST_EXPIRE_DUPS_FIRST

# Do not write events to history that are duplicates of previous events
setopt HIST_IGNORE_DUPS

# When searching history don't display results already cycled through twice
setopt HIST_FIND_NO_DUPS

# Remove extra blanks from each command line being added to history
setopt HIST_REDUCE_BLANKS

# Include more information about when the command was executed, etc
setopt EXTENDED_HISTORY

# Verify history expansion
setopt HIST_VERIFY
