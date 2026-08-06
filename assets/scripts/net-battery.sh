# Nightly network speed battery — measures real throughput with traffic the
# ISP can't classify (iperf3 over tailscale/WireGuard, 8 parallel streams,
# first 10s omitted to defeat burst boost) plus ISP-visible HTTPS from
# kernel.org, and bufferbloat (ping while saturated). Appends one row per run
# to log.csv — the longitudinal record for showing Optimum any post-honeymoon
# decline. Exits silently on any network other than MyOptimum.

DIR="$HOME/proj/claude/net-speed"
SCOOPER=100.82.172.116 # preview-sundae-scooper (AWS us-east-2), iperf3 server
LABEL=${1:-MyOptimum}

SSID=$(nmcli -t -f active,ssid dev wifi list --rescan no | awk -F: '/^yes/ {print $2}')
case "$SSID" in
MyOptimum*) ;;
*) exit 0 ;;
esac

mkdir -p "$DIR"
STAMP=$(date -Is)
OUT="$DIR/raw-$LABEL-$(date +%Y%m%d-%H%M).txt"
CSV="$DIR/log.csv"

# The iperf3 server daemon dies if the scooper reboots; revive it over ssh
if ! timeout 3 bash -c "exec 3<>/dev/tcp/$SCOOPER/5201" 2>/dev/null; then
  ssh -o BatchMode=yes -o ConnectTimeout=10 ec2-user@preview-sundae-scooper \
    'pgrep -x iperf3 >/dev/null || iperf3 -s -D'
  sleep 2
fi

iperf_mbps() { # all args passed to iperf3; prints Mbps received
  iperf3 -J "$@" >/tmp/net-battery-iperf.json &&
    jq -r '(.end.sum_received.bits_per_second/1e5|round)/10' /tmp/net-battery-iperf.json
}
ping_avg() { awk -F'/' '/^rtt/ {print $5}' "$1"; }
ping_max() { awk -F'/' '/^rtt/ {print $6}' "$1"; }
ping_loss() { grep -oE '[0-9.]+% packet loss' "$1" | cut -d% -f1; }

{
  echo "=== battery run: $LABEL, $STAMP"
  echo "wifi: $SSID"
  tailscale ping -c 4 "$SCOOPER" | tail -1 # warm up the direct wireguard path

  ping -c 30 -i 0.5 -q 1.1.1.1 >/tmp/net-battery-ping-idle.txt 2>&1 || true
  echo "idle ping: avg $(ping_avg /tmp/net-battery-ping-idle.txt) ms, max $(ping_max /tmp/net-battery-ping-idle.txt) ms"

  ping -w 40 -i 0.5 -q 1.1.1.1 >/tmp/net-battery-ping-down.txt 2>&1 &
  DOWN=$(iperf_mbps -c "$SCOOPER" -R -P 8 -t 40 -O 10)
  wait
  echo "download (AWS, encrypted): $DOWN Mbps"
  echo "ping under download: avg $(ping_avg /tmp/net-battery-ping-down.txt) ms, max $(ping_max /tmp/net-battery-ping-down.txt) ms, loss $(ping_loss /tmp/net-battery-ping-down.txt)%"

  ping -w 40 -i 0.5 -q 1.1.1.1 >/tmp/net-battery-ping-up.txt 2>&1 &
  UP=$(iperf_mbps -c "$SCOOPER" -P 8 -t 40 -O 10)
  wait
  echo "upload (AWS, encrypted): $UP Mbps"
  echo "ping under upload: avg $(ping_avg /tmp/net-battery-ping-up.txt) ms, max $(ping_max /tmp/net-battery-ping-up.txt) ms, loss $(ping_loss /tmp/net-battery-ping-up.txt)%"

  KBPS=$(curl -sL -o /dev/null --max-time 25 -w '%{speed_download}' \
    https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.tar.xz) || true
  KMBPS=$(awk "BEGIN {printf \"%.1f\", $KBPS*8/1e6}")
  echo "kernel.org HTTPS (ISP-visible): $KMBPS Mbps"

  [ -f "$CSV" ] || echo "timestamp,label,ssid,down_mbps,up_mbps,idle_ping_ms,loaded_ping_down_ms,loaded_ping_down_max_ms,loaded_ping_up_ms,loaded_ping_up_max_ms,upload_loss_pct,kernel_org_mbps" >"$CSV"
  echo "$STAMP,$LABEL,$SSID,$DOWN,$UP,$(ping_avg /tmp/net-battery-ping-idle.txt),$(ping_avg /tmp/net-battery-ping-down.txt),$(ping_max /tmp/net-battery-ping-down.txt),$(ping_avg /tmp/net-battery-ping-up.txt),$(ping_max /tmp/net-battery-ping-up.txt),$(ping_loss /tmp/net-battery-ping-up.txt),$KMBPS" >>"$CSV"
  echo "logged to $CSV"
} 2>&1 | tee "$OUT"
