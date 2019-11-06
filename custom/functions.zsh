# Generate rsa keys
function rsaKey() {
  if [ -z "${1}" ]; then
    echo "Usage: \`rsaKey file \"Your Comments\"\`"
    return 1
  fi
  if [ "$2" ]; then
    keyComment="-C \"${2}\""
  else
    keyComment=""
  fi
  ssh-keygen -t rsa -b 2048 -f "~/.ssh/${1}" "${keyComment}"
}

# Generate dsa keys
function dsaKey() {
  if [ -z "${1}" ]; then
    echo "Usage: \`dsaKey file \"Your Comments\"\`"
    return 1
  fi
  if [ "$2" ]; then
    keyComment="-C \"${2}\""
  else
    keyComment=""
  fi
  ssh-keygen -t dsa -f "~/.ssh/${1}" "${keyComment}"
}

# Install keys
function installKey() {
  if [ -z "${1}" -o -z "${2}" ]; then
    echo "Usage: \`installKey key root@example.com\`"
    return 1
  fi
  cat "~/.ssh/${1}.pub" | ssh "${2}" 'cat - >> ~/.ssh/authorized_keys'
}

function tor-enable() {
  # 'Wi-Fi' or 'Ethernet' or 'Thunderbolt Ethernet' or 'Display Ethernet'
  if [ -z "${1}" ]; then
    local INTERFACE="Wi-Fi"
  else
    local INTERFACE=$1
  fi

  # Ask for the administrator password upfront
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  # Let's roll
  sudo networksetup -setsocksfirewallproxy $INTERFACE 127.0.0.1 9050 off
  sudo networksetup -setsocksfirewallproxystate $INTERFACE on
  tor
  sudo networksetup -setsocksfirewallproxystate $INTERFACE off
}

function tor_service() {
  launchctl $1 /usr/local/opt/tor/homebrew.mxcl.tor.plist
}

function tor-start() {
  echo "$0: starting tor service...";
  tor_service load
}

function tor-stop() {
  echo "$0: stopping tor service...";
  tor_service unload
}

function tor-check() {
  echo "$0: checking if tor works...";
  if torsocks curl -s https://check.torproject.org | grep -q 'Congratulations. This browser is configured to use Tor.'; then
    echo 'The tor service works';
  else
    echo 'The tor service does NOT work';
  fi
}

# toggle iTerm2 Dock icon
# add this to your .bash_profile or .zshrc
function toggleiTerm() {
  pb='/usr/libexec/PlistBuddy'
  iTerm='/Applications/iTerm.app/Contents/Info.plist'

  echo "Do you wish to hide iTerm in Dock?"
  select ync in "Hide" "Show" "Cancel"; do
      case $ync in
          'Hide' )
            $pb -c "Add :LSUIElement bool true" $iTerm
            echo "relaunch iTerm to take effectives"
            break
            ;;
          'Show' )
            $pb -c "Delete :LSUIElement" $iTerm
            echo "run killall 'iTerm' to exit, and then relaunch it"
            break
            ;;
    'Cancel' )
      break
      ;;
      esac
  done
}

# Toggle autostart mysql
function toggleMysql() {
  LAGENT='~/Library/LaunchAgents/homebrew.mxcl.mysql.plist'
  PLIST='/usr/local/opt/mysql/homebrew.mxcl.mysql.plist'
  echo "Do you wish to load MySQL?"
  select ync in "Load" "Unload" "Cancel"; do
    case $ync in
      'Load' )
        if [ ! -f "$LAGENT" ]; then
          ln -sfv "$PLIST" "$LAGENT"
        fi
        launchctl load -w "$LAGENT"
        echo "MySQL LaunchAgent loaded"
        break
        ;;
      'Unload' )
        launchctl unload -w "$LAGENT"
        if [ -f "$LAGENT" ]; then
          rm -Rf "$LAGENT"
        fi
        echo "MySQL LaunchAgent unloaded"
        break
        ;;
      'Cancel' )
        break
        ;;
      esac
  done
}

# Clean old .dotfiles-backups
clean_dotfiles-backup() {
  if [ -z "${1}" ]; then
    local keep="5"
  else
    local keep=$1
  fi
  local dir="$HOME/.dotfiles-backup"
  [[ $dir = -* ]] && gdir=./$dir
  while IFS='' read -r -d '' entry; do
    if ((--keep < 0)); then
      filename=${entry#*$'\t'}
      rm -rf "$dir/$filename"
    fi
  done < <(gfind "$dir" \
             -mindepth 1 \
             -maxdepth 1 \
             -type d \
             -printf '%T@\t%P\0' \
           | sort -rnz)
}

# Homestead global
function homestead() {
    ( cd ~/.homestead && vagrant $* )
}

# iTerm2 profile
setup-iterm2-profile() {
  echo "Setup iTerm2 profile"
  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/iterm2"
  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
}

# Simple calculator
function calc() {
  local result=""
  result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
  #                       └─ default (when `--mathlib` is used) is 20
  #
  if [[ "$result" == *.* ]]; then
    # improve the output for decimal numbers
    printf "$result" |
    sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
        -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
        -e 's/0*$//;s/\.$//'   # remove trailing zeros
  else
    printf "$result"
  fi
  printf "\n"
}

# Create a new directory and enter it
function md() {
  mkdir -p "$@" && cd "$@"
}

# find shorthand
function f() {
    find . -name "$1"
}

# lets toss an image onto my server and pbcopy that bitch.
function scpp() {
    scp "$1" aurgasm@aurgasm.us:~/paulirish.com/i;
    echo "http://paulirish.com/i/$1" | pbcopy;
    echo "Copied to clipboard: http://paulirish.com/i/$1"
}

# Copy w/ progress
cp_p () {
  rsync -WavP --human-readable --progress $1 $2
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
  local tmpFile="${@%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

  size=$(
    stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X `stat`
    stat -c"%s" "${tmpFile}" 2> /dev/null # GNU `stat`
  )

  local cmd=""
  if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
    # the .tar file is smaller than 50 MB and Zopfli is available; use it
    cmd="zopfli"
  else
    if hash pigz 2> /dev/null; then
      cmd="pigz"
    else
      cmd="gzip"
    fi
  fi

  echo "Compressing .tar using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"
  echo "${tmpFile}.gz created successfully."
}

# Determine size of a file or total size of a directory
function fs() {
  if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh
  else
    local arg=-sh
  fi
  if [[ -n "$@" ]]; then
    du $arg -- "$@"
  else
    du $arg .[^.]* *
  fi
}

# Use Git’s colored diff when available
hash git &>/dev/null
if [ $? -eq 0 ]; then
  function diff() {
    git diff --no-index --color-words "$@"
  }
fi

# Create a data URL from a file
function dataurl() {
  local mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Create a git.io short URL
function gitio() {
  if [ -z "${1}" -o -z "${2}" ]; then
    echo "Usage: \`gitio slug url\`"
    return 1
  fi
  curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}

# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
function httpcompression() {
  encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
  local port="${1:-8000}"
  sleep 1 && open "http://localhost:${port}/" &
  # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
  local port="${1:-4000}"
  local ip=$(ipconfig getifaddr en1)
  sleep 1 && open "http://${ip}:${port}/" &
  php -S "${ip}:${port}"
}

# Compare original and gzipped file size
function gz() {
  local origsize=$(wc -c < "$1")
  local gzipsize=$(gzip -c "$1" | wc -c)
  local ratio=$(echo "$gzipsize * 100/ $origsize" | bc -l)
  printf "orig: %d bytes\n" "$origsize"
  printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
  if [ -t 0 ]; then # argument
    python -mjson.tool <<< "$*" | pygmentize -l javascript
  else # pipe
    python -mjson.tool | pygmentize -l javascript
  fi
}

# take this repo and copy it to somewhere else minus the .git stuff.
function gitexport(){
  mkdir -p "$1"
  git archive master | tar -x -C "$1"
}

# All the dig info
function digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
  printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
  # print a newline unless we’re piping the output to another program
  if [ -t 1 ]; then
    echo # newline
  fi
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
  perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
  # print a newline unless we’re piping the output to another program
  if [ -t 1 ]; then
    echo # newline
  fi
}

# Get a character’s Unicode code point
function codepoint() {
  perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"
  # print a newline unless we’re piping the output to another program
  if [ -t 1 ]; then
    echo # newline
  fi
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  echo "Testing ${domain}…"
  echo # newline

  local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
    | openssl s_client -connect "${domain}:443" 2>&1);

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText=$(echo "${tmp}" \
      | openssl x509 -text -certopt "no_header, no_serial, no_version, \
      no_signame, no_validity, no_issuer, no_pubkey, no_sigdump, no_aux");
      echo "Common Name:"
      echo # newline
      echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//";
      echo # newline
      echo "Subject Alternative Name(s):"
      echo # newline
      echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
        | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
      return 0
  else
    echo "ERROR: Certificate not found.";
    return 1
  fi
}

# Add note to Notes.app (OS X 10.8)
# Usage: `note 'title' 'body'` or `echo 'body' | note`
# Title is optional
function note() {
  local title
  local body
  if [ -t 0 ]; then
    title="$1"
    body="$2"
  else
    title=$(cat)
  fi
  osascript >/dev/null <<EOF
tell application "Notes"
  tell account "iCloud"
    tell folder "Notes"
      make new note with properties {name:"$title", body:"$title" & "<br><br>" & "$body"}
    end tell
  end tell
end tell
EOF
}

# Add reminder to Reminders.app (OS X 10.8)
# Usage: `remind 'foo'` or `echo 'foo' | remind`
function remind() {
  local text
  if [ -t 0 ]; then
    text="$1" # argument
  else
    text=$(cat) # pipe
  fi
  osascript >/dev/null <<EOF
tell application "Reminders"
  tell the default list
    make new reminder with properties {name:"$text"}
  end tell
end tell
EOF
}

# Manually remove a downloaded app or file from the quarantine
function unquarantine() {
  for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
    xattr -r -d "$attribute" "$@"
  done
}

# Install Grunt plugins and add them as `devDependencies` to `package.json`
# Usage: `gi contrib-watch contrib-uglify zopfli`
function gi() {
  local IFS=,
  eval npm install --save-dev grunt-{"$*"}
}

# `m` with no arguments opens the current directory in TextMate, otherwise
# opens the given location
function m() {
  if [ $# -eq 0 ]; then
    mate .
  else
    mate "$@"
  fi
}

# `s` with no arguments opens the current directory in Sublime Text, otherwise
# opens the given location
function s() {
  if [ $# -eq 0 ]; then
    subl .
  else
    subl "$@"
  fi
}

# `v` with no arguments opens the current directory in Vim, otherwise opens the
# given location
function v() {
  if [ $# -eq 0 ]; then
    vim .
  else
    vim "$@"
  fi
}

# `o` with no arguments opens current directory, otherwise opens the given
# location
function o() {
  if [ $# -eq 0 ]; then
    open .
  else
    open "$@"
  fi
}

# `np` with an optional argument `patch`/`minor`/`major`/`<version>`
# defaults to `patch`
function np() {
  git pull --rebase && \
  npm install && \
  npm test && \
  npm version ${1:=patch} && \
  npm publish && \
  git push origin master && \
  git push origin master --tags
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
  tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}
