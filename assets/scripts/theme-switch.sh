THEME_DATA="$HOME/.config/theme-data"
CURRENT_THEME_FILE="$HOME/.config/current-theme"
WAYBAR_THEME="$HOME/.config/waybar/theme.css"

if [ ! -d "$THEME_DATA" ]; then
  echo "Theme data not found at $THEME_DATA"
  exit 1
fi

# Determine which theme to apply
if [ "${1:-}" = "random" ]; then
  THEME=$(shuf -n1 "$THEME_DATA/themes.list")
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

# Reload waybar CSS
pkill -SIGUSR2 waybar || true

# Notify
notify-send "Theme: $THEME" "Wallpaper, borders, and bar updated" -t 3000
