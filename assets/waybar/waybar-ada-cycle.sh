# Configuration
CACHE_DIR="$HOME/.cache/waybar-ada"
MODE_FILE="$CACHE_DIR/mode"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Read current mode (default to price if file doesn't exist)
if [ ! -f "$MODE_FILE" ]; then
    CURRENT_MODE="price"
else
    CURRENT_MODE=$(cat "$MODE_FILE")
fi

# Cycle to next mode
case "$CURRENT_MODE" in
    price)
        NEW_MODE="wallet"
        ;;
    wallet)
        NEW_MODE="bank"
        ;;
    bank)
        NEW_MODE="price"
        ;;
    *)
        # Invalid mode, reset to price
        NEW_MODE="price"
        ;;
esac

# Write new mode
echo "$NEW_MODE" > "$MODE_FILE"

# Force waybar to update immediately
pkill -RTMIN+8 waybar
