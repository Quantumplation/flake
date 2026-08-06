THEME_DATA="$HOME/.config/theme-data"
CURRENT_THEME_FILE="$HOME/.config/current-theme"
WAYBAR_THEME="$HOME/.config/waybar/theme.css"
SWAYNC_STYLE="$HOME/.config/swaync/style.css"
GHOSTTY_THEME="$HOME/.config/ghostty/theme-colors"

if [ ! -d "$THEME_DATA" ]; then
  echo "Theme data not found at $THEME_DATA"
  exit 1
fi

# Warm/cool theme pools for time-based random
WARM_THEMES="gruvbox gruvbox-light everforest ayu-dark solarized-dark catppuccin-mocha catppuccin-macchiato horizon-dark"
COOL_THEMES="tokyo-night tokyo-night-storm nord kanagawa dracula rose-pine rose-pine-moon oxocarbon-dark material-palenight lumon"

# Determine which theme to apply
if [ "${1:-}" = "random" ]; then
  HOUR=$(date +%H)
  if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    POOL="$WARM_THEMES"
  else
    POOL="$COOL_THEMES"
  fi
  # Filter pool to only themes that exist in themes.list
  AVAILABLE=$(grep -xF -f <(echo "$POOL" | tr ' ' '\n') "$THEME_DATA/themes.list")
  THEME=$(echo "$AVAILABLE" | shuf -n1)
elif [ "${1:-}" = "list" ]; then
  echo "Available themes:"
  cat "$THEME_DATA/themes.list"
  if [ -f "$CURRENT_THEME_FILE" ]; then
    echo ""
    echo "Current: $(cat "$CURRENT_THEME_FILE")"
  fi
  exit 0
elif [ -n "${1:-}" ]; then
  THEME="$1"
else
  echo "Usage: theme-switch <theme-name|random|list>"
  exit 1
fi

THEME_DIR="$THEME_DATA/$THEME"
if [ ! -d "$THEME_DIR" ]; then
  echo "Theme '$THEME' not found"
  echo "Available: $(tr '\n' ', ' < "$THEME_DATA/themes.list")"
  exit 1
fi

# Record selection
echo "$THEME" > "$CURRENT_THEME_FILE"

# Apply waybar theme
cp --no-preserve=mode "$THEME_DIR/theme.css" "$WAYBAR_THEME"

# Apply swaync theme
if [ -f "$THEME_DIR/swaync.css" ]; then
  cp --no-preserve=mode "$THEME_DIR/swaync.css" "$SWAYNC_STYLE"
  swaync-client --reload-css || true
fi

# Apply ghostty theme
if [ -f "$THEME_DIR/ghostty.conf" ]; then
  mkdir -p "$(dirname "$GHOSTTY_THEME")"
  cp --no-preserve=mode "$THEME_DIR/ghostty.conf" "$GHOSTTY_THEME"
fi

# Apply tide prompt colors
if [ -f "$THEME_DIR/tide.fish" ]; then
  fish "$THEME_DIR/tide.fish"
fi

# Apply hyprland border colors
bash "$THEME_DIR/borders.sh"

# Apply wallpaper via swww with a fade transition
WALLPAPER=$(cat "$THEME_DIR/wallpaper")
if pgrep -f swww-daemon > /dev/null; then
  swww img "$WALLPAPER" --transition-type fade --transition-duration 1
else
  swww-daemon &
  sleep 1
  swww img "$WALLPAPER"
fi

# Keep lock screen wallpaper in sync (hyprlock reads through this symlink)
mkdir -p "$HOME/.cache"
ln -sfn "$WALLPAPER" "$HOME/.cache/lockscreen-wallpaper"

# Reload waybar CSS
pkill -SIGUSR2 waybar || true

# Notify
notify-send "Theme: $THEME" "Wallpaper, borders, and bar updated" -t 3000
