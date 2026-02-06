#!/bin/bash
# update-openclaw.sh
# OpenClaw Safe Update Script (Native - No Docker)
# =================================================
#
# Usage: bash update-openclaw.sh
#
# Features:
# - Pre-update backup
# - Health check after update
# - Automatic rollback on failure
#

set -e

INSTALL_DIR="/opt/openclaw"
CONFIG_DIR="$HOME/.openclaw"
BACKUP_BASE="/opt/openclaw/backups"
BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  OpenClaw Update (Native)"
echo "  $(date)"
echo "=========================================="
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# 1. Backup current config + built dist
echo -e "${GREEN}[1/6]${NC} Creating backup..."
cp "$CONFIG_DIR/config.json5" "$BACKUP_DIR/config.json5.backup" 2>/dev/null || true
cp "$INSTALL_DIR/.env.openclaw" "$BACKUP_DIR/.env.openclaw.backup" 2>/dev/null || true

# Backup dist (for rollback)
if [ -d "$INSTALL_DIR/dist" ]; then
    cp -r "$INSTALL_DIR/dist" "$BACKUP_DIR/dist.backup"
    echo "  Backed up dist/"
fi

# 2. Stop service
echo -e "${GREEN}[2/6]${NC} Stopping OpenClaw..."
sudo systemctl stop openclaw 2>/dev/null || true
sleep 2

# 3. Pull/update source
echo -e "${GREEN}[3/6]${NC} Updating source..."
cd "$INSTALL_DIR"

# Check for bundled source (SaferClaw repo includes openclaw-source/)
SAFERCLAW_SOURCE="$HOME/saferclaw/openclaw-source"
if [ -d "$SAFERCLAW_SOURCE" ] && [ -f "$SAFERCLAW_SOURCE/package.json" ]; then
    echo "  Syncing from bundled SaferClaw source..."
    rsync -a --exclude node_modules --exclude dist --delete "$SAFERCLAW_SOURCE/" "$INSTALL_DIR/"
elif [ -d ".git" ]; then
    echo "  Pulling latest changes..."
    git pull origin main
else
    echo -e "${YELLOW}  No git repo and no bundled source found at $SAFERCLAW_SOURCE${NC}"
    echo -e "${YELLOW}  To update: git pull the SaferClaw repo at ~/saferclaw, then re-run this script${NC}"
fi

# 4. Rebuild
echo -e "${GREEN}[4/6]${NC} Rebuilding..."
pnpm install --frozen-lockfile
OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
OPENCLAW_PREFER_PNPM=1 pnpm ui:build

# 5. Restart
echo -e "${GREEN}[5/6]${NC} Starting OpenClaw..."
sudo systemctl start openclaw

# 6. Health check (verify gateway is listening on port 47832)
echo -e "${GREEN}[6/6]${NC} Health check..."
HEALTH_OK=false
for i in {1..30}; do
    sleep 2
    if ss -tlnp 2>/dev/null | grep -q ':47832'; then
        HEALTH_OK=true
        break
    fi
    echo "  Waiting for gateway to start... ($i/30)"
done

if [ "$HEALTH_OK" = false ]; then
    echo -e "${RED}ERROR: Health check failed! Rolling back...${NC}"

    sudo systemctl stop openclaw 2>/dev/null || true

    # Rollback dist
    if [ -d "$BACKUP_DIR/dist.backup" ]; then
        rm -rf "$INSTALL_DIR/dist"
        cp -r "$BACKUP_DIR/dist.backup" "$INSTALL_DIR/dist"
        echo "  Restored dist/"
    fi

    # Restore config
    if [ -f "$BACKUP_DIR/config.json5.backup" ]; then
        cp "$BACKUP_DIR/config.json5.backup" "$CONFIG_DIR/config.json5"
    fi

    sudo systemctl start openclaw
    echo -e "${RED}Rollback completed.${NC}"
    echo "Check logs: journalctl -u openclaw -n 50"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  Update completed successfully!${NC}"
echo "=========================================="
echo ""
echo "Backup: $BACKUP_DIR"
echo "Status: $(sudo systemctl is-active openclaw)"
echo "Logs:   journalctl -u openclaw -f"
