#!/bin/bash
# startup-cleanup.sh
# OpenClaw Startup Cleanup Script (Native - No Docker)
# =====================================================
#
# Run before OpenClaw starts to clean orphan processes.
# Usage: ./startup-cleanup.sh
#

set -e

echo "=== OpenClaw Startup Cleanup ==="
echo "Time: $(date)"

# 1. Kill any orphan openclaw node processes (but not this script)
echo "[1/3] Cleaning orphan processes..."
pgrep -f "node.*openclaw.*gateway" | while read pid; do
    # Don't kill the systemd-managed process if restarting
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        echo "  Killing orphan process: $pid"
        kill "$pid" 2>/dev/null || true
    fi
done
sleep 1

# 2. Clean old log files (older than 30 days)
echo "[2/3] Cleaning old logs..."
find /var/log/openclaw -name "*.log" -mtime +30 -delete 2>/dev/null || true

# 3. Verify Node.js is available
echo "[3/3] Verifying Node.js..."
if ! command -v node &>/dev/null; then
    echo "ERROR: Node.js not found in PATH"
    exit 1
fi
echo "  Node.js: $(node -v)"

echo ""
echo "=== Cleanup complete ==="
