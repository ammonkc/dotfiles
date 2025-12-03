# -----------------------
# ---- eza -----
# -----------------------

EZA_THEME="${EZA_THEME:-tokyonight}"
EZA_COLOR_SCHEME="${EZA_COLOR_SCHEME:-dark}"
local eza_theme_path="$XDG_CONFIG_HOME/eza/themes/$EZA_THEME.yml"

if [[ -e $eza_theme_path ]]; then
  ln -sf $eza_theme_path $XDG_CONFIG_HOME/eza/theme.yml
fi
