#!/bin/bash
# install-openclaw.sh
# Build and install OpenClaw from source (native, no Docker)
# ===========================================================
#
# Run as your normal VPS user (NOT root):
#   bash install-openclaw.sh
#
# This script:
# 1. Copies bundled source to /opt/openclaw (if not already present)
# 2. Installs pnpm dependencies
# 3. Builds the application
# 4. Copies config files
# 5. Installs the systemd service
# 6. Starts OpenClaw
#

set -e

INSTALL_DIR="/opt/openclaw"
CONFIG_DIR="$HOME/.openclaw"
DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   OpenClaw Native Install${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check we're not root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Don't run as root! Run as your normal user.${NC}"
    echo "  Usage: bash install-openclaw.sh"
    exit 1
fi

# Check Node.js
if ! command -v node &>/dev/null; then
    echo -e "${RED}ERROR: Node.js not found. Run vps-setup-native.sh first.${NC}"
    exit 1
fi

# Check pnpm
if ! command -v pnpm &>/dev/null; then
    echo "Enabling pnpm via corepack..."
    sudo corepack enable
fi

# ============================================
# Step 1: Copy bundled source (if needed)
# ============================================
echo -e "${GREEN}[1/8] Checking source...${NC}"

BUNDLED_SOURCE="$DEPLOY_DIR/openclaw-source"

if [ ! -f "$INSTALL_DIR/package.json" ]; then
    if [ -d "$BUNDLED_SOURCE" ] && [ -f "$BUNDLED_SOURCE/package.json" ]; then
        echo "  Copying bundled source to $INSTALL_DIR..."
        sudo mkdir -p "$INSTALL_DIR"
        sudo chown "$(whoami):$(whoami)" "$INSTALL_DIR"
        rsync -a --exclude node_modules --exclude dist "$BUNDLED_SOURCE/" "$INSTALL_DIR/"
        echo -e "${GREEN}  Source copied${NC}"
    else
        echo -e "${RED}ERROR: No source found at $INSTALL_DIR and no bundled source available${NC}"
        exit 1
    fi
else
    echo "  Source already present at $INSTALL_DIR"
fi

# ============================================
# Step 2: Install dependencies
# ============================================
echo -e "${GREEN}[2/8] Installing dependencies...${NC}"
cd "$INSTALL_DIR"

pnpm install --frozen-lockfile
echo -e "${GREEN}  Dependencies installed${NC}"

# ============================================
# Step 3: Build
# ============================================
echo -e "${GREEN}[3/8] Building OpenClaw...${NC}"
OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
OPENCLAW_PREFER_PNPM=1 pnpm ui:build
echo -e "${GREEN}  Build complete${NC}"

# ============================================
# Step 4: Copy config
# ============================================
echo -e "${GREEN}[4/8] Setting up config...${NC}"
mkdir -p "$CONFIG_DIR"

if [ -f "$DEPLOY_DIR/config.json5" ] && [ ! -f "$CONFIG_DIR/config.json5" ]; then
    cp "$DEPLOY_DIR/config.json5" "$CONFIG_DIR/config.json5"
    echo "  Copied config.json5 to $CONFIG_DIR"
elif [ -f "$CONFIG_DIR/config.json5" ]; then
    echo "  Config already exists at $CONFIG_DIR/config.json5"
else
    echo -e "${YELLOW}  WARNING: No config.json5 found. Copy it manually.${NC}"
fi

# ============================================
# Step 5: Copy env file
# ============================================
echo -e "${GREEN}[5/8] Setting up environment...${NC}"

if [ -f "$DEPLOY_DIR/.env.openclaw" ] && [ ! -f "$INSTALL_DIR/.env.openclaw" ]; then
    cp "$DEPLOY_DIR/.env.openclaw" "$INSTALL_DIR/.env.openclaw"
    chmod 600 "$INSTALL_DIR/.env.openclaw"
    echo "  Copied .env.openclaw"
elif [ -f "$INSTALL_DIR/.env.openclaw" ]; then
    echo "  .env.openclaw already exists"
else
    echo -e "${YELLOW}  WARNING: No .env.openclaw found. Create it from .env.template.${NC}"
fi

# ============================================
# Step 6: Copy skills
# ============================================
echo -e "${GREEN}[6/8] Setting up skills...${NC}"

if [ -d "$DEPLOY_DIR/skills" ]; then
    mkdir -p "$INSTALL_DIR/skills"
    cp -r "$DEPLOY_DIR/skills/"* "$INSTALL_DIR/skills/" 2>/dev/null || true
    echo "  Skills copied"
else
    echo "  Using bundled skills only"
fi

# ============================================
# Step 7: Copy nginx config
# ============================================
echo -e "${GREEN}[7/8] Copying nginx config...${NC}"

if [ -f "$DEPLOY_DIR/nginx-openclaw.conf" ]; then
    cp "$DEPLOY_DIR/nginx-openclaw.conf" "$INSTALL_DIR/nginx-openclaw.conf"
    echo "  Copied nginx-openclaw.conf to $INSTALL_DIR"
else
    echo -e "${YELLOW}  WARNING: nginx-openclaw.conf not found in deploy directory.${NC}"
fi

# ============================================
# Step 8: Install systemd service
# ============================================
echo -e "${GREEN}[8/8] Installing systemd service...${NC}"

# Copy cleanup script
cp "$DEPLOY_DIR/startup-cleanup.sh" "$INSTALL_DIR/startup-cleanup.sh"
chmod +x "$INSTALL_DIR/startup-cleanup.sh"

# Install service (replace YOUR_USER placeholder with actual username)
sed "s/YOUR_USER/$(whoami)/g" "$DEPLOY_DIR/openclaw.service" | sudo tee /etc/systemd/system/openclaw.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable openclaw

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Commands:"
echo "  sudo systemctl start openclaw     # Start"
echo "  sudo systemctl stop openclaw      # Stop"
echo "  sudo systemctl restart openclaw   # Restart"
echo "  sudo systemctl status openclaw    # Status"
echo "  journalctl -u openclaw -f         # Logs"
echo ""
echo "Config: $CONFIG_DIR/config.json5"
echo "Env:    $INSTALL_DIR/.env.openclaw"
echo "Logs:   /var/log/openclaw/ + journalctl"
echo ""

# Ask to start
read -p "Start OpenClaw now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl start openclaw
    sleep 3
    sudo systemctl status openclaw --no-pager
fi
