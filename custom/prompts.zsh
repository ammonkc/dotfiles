###############################
# powerlevel9k custom_commands
###############################

################################################################
# Segment to display laravel version
prompt_laravel_ver() {
  if [ -f artisan ]; then
      local laravel_ver
      laravel_ver=$(php artisan -V | grep "Laravel Framework" | awk '{print $NF}')
      if [[ -n "$laravel_ver" ]]; then
        "$1_prompt_segment" "$0" "$2" "208" "black" "L $laravel_ver"
      fi
  fi
}

################################################################
# Segment to display PHP version number
prompt_php_ver() {
  phpfiles=(*.php(N))
  for file in $phpfiles; do
    if [[ -f $file ]]; then
        local php_ver
        php_ver=$(php -v 2>&1 | grep -oe "^PHP\s*[0-9.]*")

        if [[ -n "$php_ver" ]]; then
          "$1_prompt_segment" "$0" "$2" "fuchsia" "grey93" "$php_ver"
        fi
        break
    fi
  done
}
