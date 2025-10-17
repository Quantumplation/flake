# Configuration
CACHE_DIR="${HOME}/.cache/waybar-ada"
MODE_FILE="${CACHE_DIR}/mode"
VALUES_FILE="${CACHE_DIR}/values.json"
PRICE_HISTORY_FILE="${CACHE_DIR}/price_history.json"
ADDRESS_BALANCES_FILE="${CACHE_DIR}/address_balances.json"
NOTIFICATION_LOG_FILE="${CACHE_DIR}/notification_log.json"

# Set defaults if not injected (for variables that might come from Nix)
BLOCKFROST_KEY_FILE="${BLOCKFROST_KEY_FILE:-/run/secrets/blockfrost-mainnet}"
MERCURY_KEY_FILE="${MERCURY_KEY_FILE:-/run/secrets/mercury-apikey}"
ADDRESSES_FILE="${ADDRESSES_FILE:-${HOME}/.config/waybar-ada/addresses.conf}"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR" 2>/dev/null || true

# Initialize mode file
if [ ! -f "$MODE_FILE" ]; then
    echo "price" > "$MODE_FILE" 2>/dev/null || echo "price"
fi

MODE=$(cat "$MODE_FILE" 2>/dev/null) || MODE="price"

# Initialize values file
if [ ! -f "$VALUES_FILE" ]; then
    echo '{"price":0,"wallet":0,"bank":0,"timestamp":0}' > "$VALUES_FILE" 2>/dev/null || true
fi

# Initialize price history file (for 4-hour tracking)
if [ ! -f "$PRICE_HISTORY_FILE" ]; then
    echo '[]' > "$PRICE_HISTORY_FILE" 2>/dev/null || true
fi

# Initialize address balances file (for per-address notifications)
if [ ! -f "$ADDRESS_BALANCES_FILE" ]; then
    echo '{}' > "$ADDRESS_BALANCES_FILE" 2>/dev/null || true
fi

# Initialize notification log file (to prevent duplicate notifications)
if [ ! -f "$NOTIFICATION_LOG_FILE" ]; then
    echo '{}' > "$NOTIFICATION_LOG_FILE" 2>/dev/null || true
fi

# Function to check if we should send notification (prevent duplicates within 5 minutes)
should_notify() {
    local notification_key="$1"
    local current_time
    current_time=$(date +%s)
    
    # Load notification log
    local notification_log
    notification_log=$(cat "$NOTIFICATION_LOG_FILE" 2>/dev/null) || notification_log="{}"
    
    # Check last notification time for this key
    local last_notified
    last_notified=$(echo "$notification_log" | grep -o "\"${notification_key}\":[0-9]*" | cut -d':' -f2) || last_notified="0"
    
    if [ -z "$last_notified" ]; then
        last_notified="0"
    fi
    
    # If notified within last 5 minutes (300 seconds), skip
    local time_diff=$((current_time - last_notified))
    if [ "$time_diff" -lt 300 ]; then
        return 1  # Don't notify
    fi
    
    # Update log with current time
    # shellcheck disable=SC2001
    if echo "$notification_log" | grep -q "\"${notification_key}\":"; then
        # Update existing entry
        # shellcheck disable=SC2001
        notification_log=$(echo "$notification_log" | sed "s/\"${notification_key}\":[0-9]*/\"${notification_key}\":${current_time}/")
    else
        # Add new entry
        # shellcheck disable=SC2001
        notification_log=$(echo "$notification_log" | sed "s/}$/,\"${notification_key}\":${current_time}}/" | sed 's/{,/{/')
    fi
    
    echo "$notification_log" > "$NOTIFICATION_LOG_FILE" 2>/dev/null || true
    return 0  # OK to notify
}

# Function to output JSON
output_json() {
    local text="$1"
    local tooltip="$2"
    local class="$3"
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

# Function to send notification if value changed
notify_if_changed() {
    local key="$1"
    local new_value="$2"
    local label="$3"

    # Return early if values file doesn't exist
    [ -f "$VALUES_FILE" ] || return 0

    local prev_value
    prev_value=$(grep -o "\"$key\":[0-9.]*" "$VALUES_FILE" 2>/dev/null | cut -d':' -f2) || prev_value="0"

    if [ -z "$prev_value" ]; then
        prev_value="0"
    fi

    # Don't notify if previous value was 0 (first run after reload)
    if [ "$prev_value" = "0" ]; then
        sed -i "s/\"$key\":[0-9.]*/\"$key\":$new_value/" "$VALUES_FILE" 2>/dev/null || true
        return 0
    fi

    if [ "$prev_value" != "$new_value" ]; then
        local diff
        diff=$(echo "$new_value - $prev_value" | bc 2>/dev/null) || return 0
        local diff_formatted
        diff_formatted=$(printf "%.2f" "$diff" 2>/dev/null) || return 0

        # For bank, always notify on any change
        if [ "$key" = "bank" ]; then
            if should_notify "bank_${new_value}"; then
                if echo "$diff" | grep -q "^-" 2>/dev/null; then
                    notify-send "💸 $label Decreased" "$label: \$${new_value}, Change: ${diff_formatted}" -u normal 2>/dev/null || true
                else
                    notify-send "💰 $label Increased" "$label: \$${new_value}, Change: +${diff_formatted}" -u normal 2>/dev/null || true
                fi
            fi
        fi
        
        # For price, check 4-hour window and 10% threshold
        if [ "$key" = "price" ]; then
            check_price_threshold "$new_value"
        fi
    fi

    sed -i "s/\"$key\":[0-9.]*/\"$key\":$new_value/" "$VALUES_FILE" 2>/dev/null || true
}

# Function to check if ADA price changed >10% in 4-hour window
check_price_threshold() {
    local current_price="$1"
    local current_time
    current_time=$(date +%s)
    
    # Add current price to history
    local history
    history=$(cat "$PRICE_HISTORY_FILE" 2>/dev/null) || history="[]"
    
    # Append current price with timestamp
    echo "$history" | grep -q '^\[\]$' && history='[]'
    
    # Add new entry (timestamp:price)
    local new_entry="${current_time}:${current_price}"
    # shellcheck disable=SC2001
    echo "$history" | sed "s/\]$/, \"$new_entry\"]/" | sed 's/\[\[\]/[/' > "$PRICE_HISTORY_FILE" 2>/dev/null || true
    
    # Find price from 4 hours ago (14400 seconds)
    local four_hours_ago=$((current_time - 14400))
    local old_price=""
    
    # Read history and find closest price to 4 hours ago
    while IFS=':' read -r timestamp price; do
        if [ "$timestamp" -ge "$four_hours_ago" ] 2>/dev/null; then
            if [ -z "$old_price" ]; then
                old_price="$price"
            fi
        fi
    done < <(echo "$history" | tr -d '[]",' | tr ' ' '\n' | grep ':')
    
    # If we have an old price, check if change is > 10%
    if [ -n "$old_price" ] && [ "$old_price" != "0" ]; then
        local percent_change
        percent_change=$(echo "scale=2; (($current_price - $old_price) / $old_price) * 100" | bc 2>/dev/null) || return 0
        
        # Check if absolute value > 10
        local abs_change
        abs_change=$(echo "$percent_change" | tr -d '-')
        
        if [ "$(echo "$abs_change > 10" | bc 2>/dev/null)" = "1" ]; then
            if should_notify "price_alert_${current_price}"; then
                if echo "$percent_change" | grep -q "^-"; then
                    notify-send "📉 ADA Price Alert" "Down ${abs_change}% in 4 hours to \$${current_price}" -u critical 2>/dev/null || true
                else
                    notify-send "📈 ADA Price Alert" "Up ${abs_change}% in 4 hours to \$${current_price}" -u critical 2>/dev/null || true
                fi
            fi
        fi
    fi
    
    # Clean up old entries (older than 5 hours)
    local five_hours_ago=$((current_time - 18000))
    local cleaned_history="["
    local first=true
    
    while IFS=':' read -r timestamp price; do
        if [ "$timestamp" -ge "$five_hours_ago" ] 2>/dev/null; then
            if [ "$first" = true ]; then
                cleaned_history="${cleaned_history}\"${timestamp}:${price}\""
                first=false
            else
                cleaned_history="${cleaned_history}, \"${timestamp}:${price}\""
            fi
        fi
    done < <(echo "$history" | tr -d '[]",' | tr ' ' '\n' | grep ':')
    
    cleaned_history="${cleaned_history}]"
    echo "$cleaned_history" > "$PRICE_HISTORY_FILE" 2>/dev/null || true
}

# Function to fetch ADA price
fetch_ada_price() {
    local response
    local query='{"query":"query { assets { byId(id: \"ada.lovelace\") { price { ratio } } } }"}'
    
    response=$(curl -s -m 5 -X POST -H "Content-Type: application/json" -d "$query" "https://api.sundae.fi/graphql" 2>/dev/null) || {
        output_json "₳ --" "ADA Price: API Unavailable" "error"
        return 0
    }
    
    if [ -z "$response" ]; then
        output_json "₳ --" "ADA Price: No response" "error"
        return 0
    fi

    local price
    price=$(echo "$response" | grep -o '"ratio":[0-9.]*' | head -n1 | cut -d':' -f2)

    if [ -z "$price" ]; then
        if echo "$response" | grep -q '"errors"'; then
            output_json "₳ --" "ADA Price: API Error" "error"
        else
            output_json "₳ --" "ADA Price: Parse Error" "error"
        fi
        return 0
    fi

    local price_formatted
    price_formatted=$(printf "%.2f" "$price")
    
    notify_if_changed "price" "$price" "ADA Price"

    local prev_price
    prev_price=$(grep -o '"price":[0-9.]*' "$VALUES_FILE" | cut -d':' -f2 2>/dev/null) || prev_price="0"
    
    local class="neutral"
    local tooltip="ADA/USD: \$${price_formatted}"
    
    if [ -n "$prev_price" ] && [ "$prev_price" != "0" ]; then
        local change
        change=$(echo "scale=4; (($price - $prev_price) / $prev_price) * 100" | bc 2>/dev/null) || change="0"
        local change_formatted
        change_formatted=$(printf "%.2f" "$change")

        if echo "$change" | grep -q "^-"; then
            class="down"
            tooltip="${tooltip}, 24h: ${change_formatted}% ↓"
        else
            class="up"
            tooltip="${tooltip}, 24h: +${change_formatted}% ↑"
        fi
    fi

    tooltip="${tooltip}, Right-click to cycle"
    output_json "₳ \$${price_formatted}" "$tooltip" "$class"
}

# Function to fetch wallet balance
fetch_wallet_balance() {
    if [ ! -f "$ADDRESSES_FILE" ]; then
        output_json "👛 --" "Config file not found" "error"
        return 0
    fi
    
    if [ ! -f "$BLOCKFROST_KEY_FILE" ]; then
        output_json "👛 --" "Blockfrost key not found" "error"
        return 0
    fi
    
    local blockfrost_key
    blockfrost_key=$(cat "$BLOCKFROST_KEY_FILE" 2>/dev/null) || {
        output_json "👛 --" "Could not read key" "error"
        return 0
    }
    
    # Load previous address balances
    local prev_balances
    prev_balances=$(cat "$ADDRESS_BALANCES_FILE" 2>/dev/null) || prev_balances="{}"
    
    local total_lovelace=0
    local address_count=0
    local failed_addresses=0
    local new_balances="{"
    local first_balance=true
    
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in
            \#*) continue ;;
        esac
        
        # Check if this address is watched (has # * marker)
        local is_watched=false
        if echo "$line" | grep -q '# \*'; then
            is_watched=true
        fi
        
        # Extract just the address (remove comments)
        local address
        # shellcheck disable=SC2001
        address=$(echo "$line" | sed 's/#.*//' | tr -d '[:space:]')
        
        [ -z "$address" ] && continue
        
        address_count=$((address_count + 1))
        
        local response
        local amount=""
        
        case "$address" in
            stake1*)
                response=$(curl -s -m 10 -H "project_id: $blockfrost_key" \
                    "https://cardano-mainnet.blockfrost.io/api/v0/accounts/$address" 2>/dev/null) || {
                    failed_addresses=$((failed_addresses + 1))
                    continue
                }
                
                if echo "$response" | grep -q '"error"'; then
                    failed_addresses=$((failed_addresses + 1))
                    continue
                fi
                
                # For stake addresses: controlled_amount + rewards_sum = total balance
                local controlled
                controlled=$(echo "$response" | grep -o '"controlled_amount":"[0-9]*"' | grep -o '[0-9]*')
                local rewards
                rewards=$(echo "$response" | grep -o '"rewards_sum":"[0-9]*"' | grep -o '[0-9]*')
                
                # Default to 0 if not found
                controlled="${controlled:-0}"
                rewards="${rewards:-0}"
                
                # Sum controlled + rewards
                amount=$((controlled + rewards))
                ;;
            *)
                response=$(curl -s -m 10 -H "project_id: $blockfrost_key" \
                    "https://cardano-mainnet.blockfrost.io/api/v0/addresses/$address" 2>/dev/null) || {
                    failed_addresses=$((failed_addresses + 1))
                    continue
                }
                
                if echo "$response" | grep -q '"error"'; then
                    failed_addresses=$((failed_addresses + 1))
                    continue
                fi
                
                amount=$(echo "$response" | grep -o '"amount":\[{"unit":"lovelace","quantity":"[0-9]*"' | \
                    grep -o '[0-9]*"$' | tr -d '"')
                ;;
        esac
        
        if [ -n "$amount" ] && [ "$amount" -gt 0 ] 2>/dev/null; then
            total_lovelace=$((total_lovelace + amount))
            
            # Store balance for this address
            if [ "$first_balance" = true ]; then
                new_balances="${new_balances}\"${address}\":${amount}"
                first_balance=false
            else
                new_balances="${new_balances},\"${address}\":${amount}"
            fi
            
            # Check if this watched address received funds
            if [ "$is_watched" = true ]; then
                local prev_amount
                prev_amount=$(echo "$prev_balances" | grep -o "\"${address}\":[0-9]*" | cut -d':' -f2) || prev_amount="0"
                
                if [ -z "$prev_amount" ]; then
                    prev_amount="0"
                fi
                
                # Only notify if we have a previous balance (not first run) and balance increased
                if [ "$prev_amount" != "0" ] && [ "$amount" -gt "$prev_amount" ] 2>/dev/null; then
                    local ada_received
                    ada_received=$(echo "scale=2; ($amount - $prev_amount) / 1000000" | bc 2>/dev/null)
                    
                    # Truncate address for notification
                    local short_addr
                    short_addr=$(echo "$address" | cut -c1-12)
                    
                    # Only notify if we haven't notified for this address+amount in the last 5 minutes
                    if should_notify "addr_${address}_${amount}"; then
                        notify-send "💰 Funds Received" "₳${ada_received} received at ${short_addr}..." -u normal 2>/dev/null || true
                    fi
                fi
            fi
        fi
    done < "$ADDRESSES_FILE"
    
    new_balances="${new_balances}}"
    echo "$new_balances" > "$ADDRESS_BALANCES_FILE" 2>/dev/null || true
    
    if [ "$address_count" -eq 0 ]; then
        output_json "👛 --" "No addresses in config" "error"
        return 0
    fi
    
    local total_ada
    total_ada=$(echo "scale=2; $total_lovelace / 1000000" | bc 2>/dev/null) || {
        output_json "👛 --" "Calculation error" "error"
        return 0
    }
    
    notify_if_changed "wallet" "$total_ada" "Wallet Balance"
    
    local formatted_balance
    formatted_balance=$(echo "$total_ada" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' 2>/dev/null)
    
    if [ -z "$formatted_balance" ]; then
        formatted_balance="$total_ada"
    fi
    
    local tooltip="Wallet: ₳${formatted_balance}, Addresses: ${address_count}"
    
    if [ "$failed_addresses" -gt 0 ]; then
        tooltip="${tooltip}, Failed: ${failed_addresses}"
    fi
    
    tooltip="${tooltip}, Right-click to cycle"
    output_json "👛 ₳${formatted_balance}" "$tooltip" "neutral"
}

# Function to fetch bank balance
fetch_bank_balance() {
    # Check if Mercury key exists
    if [ ! -f "$MERCURY_KEY_FILE" ]; then
        output_json "🏦 --" "Mercury key not found" "error"
        return 0
    fi
    
    local mercury_key
    mercury_key=$(cat "$MERCURY_KEY_FILE" 2>/dev/null) || {
        output_json "🏦 --" "Could not read Mercury key" "error"
        return 0
    }
    
    # Query Mercury API
    local response
    response=$(curl -s -m 10 -H "Authorization: Bearer $mercury_key" \
        "https://api.mercury.com/api/v1/accounts" 2>/dev/null) || {
        output_json "🏦 --" "Mercury API unavailable" "error"
        return 0
    }
    
    if [ -z "$response" ]; then
        output_json "🏦 --" "Mercury: No response" "error"
        return 0
    fi
    
    # Check for errors
    if echo "$response" | grep -q '"errors"'; then
        output_json "🏦 --" "Mercury API error" "error"
        return 0
    fi
    
    # Extract all currentBalance values and sum them
    local balances
    balances=$(echo "$response" | grep -o '"currentBalance":[0-9.]*' | cut -d':' -f2)
    
    if [ -z "$balances" ]; then
        output_json "🏦 --" "Could not parse balances" "error"
        return 0
    fi
    
    # Sum all balances - handle single or multiple accounts
    local total_balance
    
    total_balance=$(echo "$balances" | awk '{sum += $1} END {printf "%.2f", sum}')
    
    # Validate we got a number
    if [ -z "$total_balance" ]; then
        output_json "🏦 --" "Balance calculation failed" "error"
        return 0
    fi
    
    # Ensure we have 2 decimal places
    total_balance=$(printf "%.2f" "$total_balance" 2>/dev/null) || total_balance="0.00"
    
    # Check for changes and notify
    notify_if_changed "bank" "$total_balance" "Mercury Balance"
    
    # Format with thousand separators
    local formatted_balance
    formatted_balance=$(echo "$total_balance" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' 2>/dev/null)
    
    if [ -z "$formatted_balance" ]; then
        formatted_balance="$total_balance"
    fi
    
    # Count accounts
    local account_count
    account_count=$(echo "$response" | grep -o '"id"' | wc -l | tr -d ' ')
    
    # Build display strings
    local dollar='$'
    local tooltip="Mercury: ${dollar}${formatted_balance}, Accounts: ${account_count}, Right-click to cycle"
    local display_text="🏦 ${dollar}${formatted_balance}"
    
    output_json "$display_text" "$tooltip" "neutral"
}

# Main logic - always output something even if errors occur
main() {
    case "$MODE" in
        price) fetch_ada_price ;;
        wallet) fetch_wallet_balance ;;
        bank) fetch_bank_balance ;;
        *)
            echo "price" > "$MODE_FILE" 2>/dev/null || true
            fetch_ada_price
            ;;
    esac
}

# Run main and ensure we always output JSON
main || output_json "⚠ --" "Script error occurred" "error"
