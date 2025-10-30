#!/bin/bash
# Self-healing service monitor
# Monitors a list of systemd services, attempts restart, writes Prometheus textfile metrics


set -euo pipefail


# Services to monitor (modify as needed)
SERVICES=("nginx" "docker" "sshd")


# Where Node Exporter textfile collector reads metrics
METRICS_FILE="/tmp/service_status.prom"
LOGFILE="/var/log/selfheal.log"


# Ensure metrics file exists and is writable
mkdir -p "$(dirname "$METRICS_FILE")"
: > "$METRICS_FILE"


for SERVICE in "${SERVICES[@]}"; do
# Check active state (returns 0 if active)
if systemctl is-active --quiet "$SERVICE"; then
echo "service_status{service=\"$SERVICE\"} 1" >> "$METRICS_FILE"
else
echo "service_status{service=\"$SERVICE\"} 0" >> "$METRICS_FILE"
echo "$(date --iso-8601=seconds): $SERVICE is down. Attempting restart..." >> "$LOGFILE"


# Attempt restart
if systemctl restart "$SERVICE"; then
# small wait and re-check
sleep 3
if systemctl is-active --quiet "$SERVICE"; then
echo "$(date --iso-8601=seconds): $SERVICE restarted successfully." >> "$LOGFILE"
else
echo "$(date --iso-8601=seconds): $SERVICE restart attempted but still not active." >> "$LOGFILE"
fi
else
echo "$(date --iso-8601=seconds): $SERVICE failed to restart (systemctl restart returned non-zero)." >> "$LOGFILE"
fi
fi
done
