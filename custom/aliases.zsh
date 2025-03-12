# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadshell="source $HOME/.zshrc"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias ll="/opt/homebrew/opt/coreutils/libexec/gnubin/ls -AhlFo --color --group-directories-first"
alias phpstorm='open -a /Applications/PhpStorm.app "`pwd`"'
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias c="clear"
alias compile="commit 'compile'"
alias version="commit 'version'"

# Easier navigation: .., ..., ~ and -
alias zz="cd -"
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias home="cd ~"
alias -- -="cd -"

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
    colorflag="--color"
else # OS X `ls`
    colorflag="-G"
fi

# List all files colorized in long format
alias l="ls -l ${colorflag}"

# List all files colorized in long format, including dot files
alias la="ls -la ${colorflag}"

# List only directories
alias lsd='ls -l | grep "^d"'

# File system list
alias lss='ls -aFhlG'
alias lsa='ls -la'
alias lsl='ls -l'
alias lsh='ls -FhlG'

alias cat='bat'

# Always use color output for `ls`
if [[ "$OSTYPE" =~ ^darwin ]]; then
    alias ls="command ls -G"
else
    alias ls="command ls --color"
    export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
fi

# Network
alias myip='curl ifconfig.me/ip'
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
# Enhanced WHOIS lookups
alias whois="whois -h whois-servers.net"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# File size
alias fs="stat -f \"%z bytes\""

# Directories
alias dotfiles="cd $DOTFILES"
alias library="cd $HOME/Library"
alias sites="cd $HOME/Developer/code"
alias src="cd $HOME/Developer/src"
# allegro.test project directory
alias dev="cd $HOME/Developer/code/allegro.test"

# Laravel
alias a="php artisan"
alias fresh="php artisan migrate:fresh --seed"
alias tinker="php artisan tinker"
alias seed="php artisan db:seed"
alias serve="php artisan serve"
alias artest="php -d xdebug.mode="off" -d memory_limit=-1 -d max_execution_time=0 artisan test --parallel -vvv"

#ILT docker
alias spin="./spin"
alias sup="./spin up"
alias sdown="./spin down"
alias spa="./spin artisan"
alias spfresh="./spin artisan migrate:fresh --seed"
alias sptinker="./spin artisan tinker"
alias spseed="./spin artisan db:seed"
alias spserve="./spin artisan serve"
alias docker-up="USER_ID=$(id -u) GROUP_ID=$(id -g) docker compose -f docker-compose.yaml --profile sftp up --force-recreate --build --detach --remove-orphans"
alias docker-down="USER_ID=$(id -u) GROUP_ID=$(id -g) docker compose -f docker-compose.yaml --profile sftp down"
alias dup=docker-up
alias ddown=docker-down
alias dart=docker-artisan

# Homebrew aliases
alias install='brew install'
alias reinstall='brew reinstall'
alias update='brew update'
alias upgrade='brew upgrade'

# Dotfiles update
alias dotfilesUpdate='bash -c "$( curl -fsSL https://raw.github.com/ammonkc/dotfiles/master/bootstrap.sh )"'

# Vundle InstallBundle
alias vundleUpdate="vim +BundleInstall! +BundleClean +qall"
alias vundleInstall='vim +BundleInstall +qall'

# vim
alias svim='vim sudo:'

# PHP
alias cfresh="rm -rf vendor/ composer.lock && composer i"
alias composer="php -d memory_limit=-1 /opt/homebrew/bin/composer"
# determine versions of PHP installed with HomeBrew
installedPhpVersions=($(brew ls --versions | ggrep -E 'php(@.*)?\s' | ggrep -oP '(?<=\s)\d\.\d' | uniq | sort))

# create alias for every version of PHP installed with HomeBrew
for phpVersion in ${installedPhpVersions[*]}; do
    value="{"

    for otherPhpVersion in ${installedPhpVersions[*]}; do
        if [ "${otherPhpVersion}" = "${phpVersion}" ]; then
            continue;
        fi

        value="${value} brew unlink php@${otherPhpVersion};"
    done

    value="${value} brew link php@${phpVersion} --force --overwrite; } &> /dev/null && php -v"

    alias "php${phpVersion}"="${value}"
done

# JS
alias nfresh="rm -rf node_modules/ package-lock.json && npm install"
alias watch="npm run watch"

# Docker
alias docker-composer="docker-compose"

# SQL Server
alias mssql="docker run -e ACCEPT_EULA=Y -e SA_PASSWORD=LaravelWow1986! -p 1433:1433 mcr.microsoft.com/mssql/server:2017-latest"

# Git
alias gst="git status"
alias gb="git branch"
alias gc="git checkout"
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias diff="git diff"
alias force="git push --force"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit wip"
# Undo a `git push`
alias undopush="git push -f origin HEAD^:master"
# git root
alias gr='[ ! -z `git rev-parse --show-cdup` ] && cd `git rev-parse --show-cdup || pwd`'
