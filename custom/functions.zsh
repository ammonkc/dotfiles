# toggle xdebug
function xdebug() {
  iniFileLocation="/opt/homebrew/etc/php/8.0/conf.d/ext-xdebug.ini"
  currentLine=`cat $iniFileLocation | grep xdebug.so`
  if [[ $currentLine =~ ^#zend_extension ]]
  then
    sed -i -e 's/^#zend_extension/zend_extension/g' $iniFileLocation
    echo "xdebug is now active"
  else
    sed -i -e 's/^zend_extension/#zend_extension/g' $iniFileLocation
    echo "xdebug is now inactive"
  fi
}

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

# Homestead global
function homestead() {
    ( cd ~/.homestead && vagrant $* )
}

# Create a new directory and enter it
function md() {
  mkdir -p "$@" && cd "$@"
}

# find shorthand
function f() {
    find . -name "$1"
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

# Create a git.io short URL
function gitio() {
  if [ -z "${1}" -o -z "${2}" ]; then
    echo "Usage: \`gitio slug url\`"
    return 1
  fi
  curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}
