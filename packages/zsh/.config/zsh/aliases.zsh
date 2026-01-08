# ---------------------------------
# Aliases
# ---------------------------------

alias c='clear'
alias q='exit'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ---- navigation -----
alias ..="cd ../"
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias ~="cd ~" 						# `cd` is probably faster to type though
alias home="cd ~"
alias -- -="cd -"
alias zz="cd -"
alias la='ls -lAh'
alias lsa="ls -aG"
alias ldot='ls -ld .*'				# List dotfiles
alias lsd='ls -l | grep "^d"'		# List only directories

# ---- neovim (nvim) -----
if (( $+commands[nvim] )); then
	alias vi='nvim'
	alias vim='nvim'
	alias svi='sudo nvim'
	alias svim='nvim sudo:'
	alias vis='nvim "+set si"'
elif (( $+commands[vim] )); then
	alias vi='vim'
	alias svi='sudo vim'
	alias svim='vim sudo:'
	alias vis='vim "+set si"'
fi

# ---- Eza (better ls) -----
if (( $+commands[eza] )); then
    alias ls="eza --icons=always"
fi

# ---- Bat (better cat) -----
# Link: https://github.com/sharkdp/bat
if (( $+commands[bat] )); then
    alias cat='bat'
fi

# ---- gnu grep -----
if (( $+commands[ggrep] )); then
	alias grep='ggrep'
fi

# ---- gnu sed -----
if (( $+commands[gsed] )); then
	alias sed='gsed'
fi

# ---- gnu tar -----
if (( $+commands[gtar] )); then
	alias tar='gtar'
fi

# ---- gnu awk -----
if (( $+commands[gawk] )); then
	alias awk='gawk'
fi

# ---- lazygit -----
# Link: https://github.com/jesseduffield/lazygit
if (( $+commands[lazygit] )); then
    alias lg='lazygit'
fi

# ---- homebrew -----
if (( $+commands[brew] )); then
	alias brw='brew'
fi

# Get local IP addresses
if (( $+commands[ip] )); then
    alias iplocal="ip -br -c a"
else
    alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
fi

# ---- Network -----
alias myip='curl -s ifconfig.me/ip'
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"  # renamed from 'ip' to avoid shadowing Linux ip command
alias localip="ipconfig getifaddr en0"  # en0 is more common for WiFi on modern Macs
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias whois="whois -h whois-servers.net"	# Enhanced WHOIS lookups
alias flush="dscacheutil -flushcache"		# Flush Directory Service cache

# ---- PHP -----
alias cfresh="rm -rf vendor/ composer.lock && composer i"
alias composer="php -d memory_limit=-1 /opt/homebrew/bin/composer"
# PHP version switching: use `phpswitch <version>` function (autoloaded from $ZDOTDIR/functions)
alias sphp='phpswitch'

# ---- Laravel -----
alias a="php artisan"
alias fresh="php artisan migrate:fresh --seed"
alias tinker="php artisan tinker"
alias seed="php artisan db:seed"
alias serve="php artisan serve"
alias artest='php -d xdebug.mode=off -d memory_limit=-1 -d max_execution_time=0 artisan test --parallel -vvv'

# ---- Docker -----
alias docker-composer="docker compose"
alias docker-killall="docker ps | tail -n +2 | awk '{ print \$1 }' | xargs docker kill"
# ---- IDL Docker -----
alias docker-up="docker compose --profile sftp up --force-recreate --build --detach --remove-orphans"
alias docker-down="docker compose --profile sftp down"
alias dup=docker-up
alias ddown=docker-down
alias dart=docker-artisan

# ---- AWS SSO -----
alias genailogin='aws sso login --profile genai'

# ---- Taskfile (dotfiles) -----
# Short alias for the dotfiles wrapper script
alias dot='dotfiles'

# ---- Shortcuts -----
# Alias to clear cached-eval caches (uses function defined in functions/clear-cached-eval)
alias clear-zsh-cache='clear-cached-eval'
alias reloadshell="source $ZDOTDIR/.zshrc"
alias reload-aliases='source $ZDOTDIR/aliases.zsh'
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"

# ---- Git -----
# Undo a `git push`
alias undopush="git push -f origin HEAD^:master"
