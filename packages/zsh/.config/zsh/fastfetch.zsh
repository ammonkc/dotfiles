# -----------------------
# ---- FastFetch -----
# -----------------------
if [[ "${FASTFETCH_STARTUP}" == "true" ]] && (( $+commands[fastfetch] )); then
  local logo_type=""
  local logo_source=""
  local logo_pad_left=""
  local logo_pad_top=""

  # Override if on work machine
  if (( $+commands[kandji] )); then
    logo_type="file"
    logo_source="$XDG_CONFIG_HOME/fastfetch/ncino.txt"
    logo_pad_left="4"
    logo_pad_top="4"
  fi

  local args=(--config $XDG_CONFIG_HOME/fastfetch/config.jsonc)
  [[ -n "${logo_source}" ]] && args+=(--logo "${logo_source}")
  [[ -n "${logo_type}" ]] && args+=(--logo-type "${logo_type}")
  [[ -n "${logo_pad_left}" ]] && args+=(--logo-padding-left "${logo_pad_left}")
  [[ -n "${logo_pad_top}" ]] && args+=(--logo-padding-top "${logo_pad_top}")

  fastfetch "${args[@]}"
fi
