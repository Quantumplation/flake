# Configuration
CACHE_DIR="$HOME/.cache/waybar-ada"
MODE_FILE="$CACHE_DIR/mode"

# Read current mode
if [ ! -f "$MODE_FILE" ]; then
    MODE="price"
else
    MODE=$(cat "$MODE_FILE")
fi

# Open appropriate URL based on mode
case "$MODE" in
    price)
        xdg-open "https://taptools.io/charts/token?pairID=0be55d262b29f564998ff81efe21bdc0022621c12f15af08d0f2ddb1.7339a8bcmeant46953cd0b223842a73db6e4a56dce6fb96ecdbefcc67e6164615f6c6f76656c616365"
        ;;
    wallet)
        xdg-open "https://eternl.io"
        ;;
    bank)
        xdg-open "https://app.mercury.com"
        ;;
    *)
        # Default to taptools
        xdg-open "https://taptools.io/charts/token?pairID=0be55d262b29f564998ff81efe21bdc0022621c12f15af08d0f2ddb1.7339a8bcmeant46953cd0b223842a73db6e4a56dce6fb96ecdbefcc67e6164615f6c6f76656c616365"
        ;;
esac
