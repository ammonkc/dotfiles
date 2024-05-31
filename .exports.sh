# Make vim the default editor
export EDITOR="vim"

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8


# load ssh agent
# ssh-add --apple-load-keychain -q

# 1password ssh agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# xterm colors
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

if tput setaf 1 &> /dev/null; then
    tput sgr0
    if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
        MAGENTA=$(tput setaf 9)
        ORANGE=$(tput setaf 172)
        GREEN=$(tput setaf 190)
        PURPLE=$(tput setaf 141)
        WHITE=$(tput setaf 0)
    else
        MAGENTA=$(tput setaf 5)
        ORANGE=$(tput setaf 4)
        GREEN=$(tput setaf 2)
        PURPLE=$(tput setaf 1)
        WHITE=$(tput setaf 7)
    fi
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    MAGENTA="\033[1;31m"
    ORANGE="\033[1;33m"
    GREEN="\033[1;32m"
    PURPLE="\033[1;35m"
    WHITE="\033[1;37m"
    BOLD=""
    RESET="\033[m"
fi

export MAGENTA
export ORANGE
export GREEN
export PURPLE
export WHITE
export BOLD
export RESET

# Node Path
export NODE_PATH="/usr/local/bin/node"

# Homebrew Ruby
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"

# Private env variables
[[ -f "$HOME/.private_env" ]] && source "$HOME/.private_env"
