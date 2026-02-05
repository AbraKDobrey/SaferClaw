#!/bin/bash
# vps-setup-native.sh
# OpenClaw Native VPS Setup (No Docker)
# ======================================
#
# Installs OpenClaw directly on the VPS with sudo for your user.
# Replaces the Docker-based deployment.
#
# INSTRUCTIES:
# 1. Vul de variabelen hieronder in
# 2. Run als root: sudo bash vps-setup-native.sh
#

set -e

# ===== VUL DEZE IN =====
DOMAIN=""               # bijv: "myopenclaw.duckdns.org"
DUCKDNS_TOKEN=""        # je token van duckdns.org
DUCKDNS_SUBDOMAIN=""    # bijv: "myopenclaw"
OPENCLAW_USER=""        # je VPS username
# =======================

# Kleuren
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   OpenClaw Native VPS Setup${NC}"
echo -e "${GREEN}   (No Docker)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Run as root (sudo bash vps-setup-native.sh)${NC}"
    exit 1
fi

# Validate
if [ -z "$OPENCLAW_USER" ]; then
    echo -e "${RED}ERROR: Set OPENCLAW_USER variable at the top of this script${NC}"
    exit 1
fi

if ! id "$OPENCLAW_USER" &>/dev/null; then
    echo -e "${RED}ERROR: User $OPENCLAW_USER does not exist${NC}"
    exit 1
fi

OPENCLAW_HOME=$(eval echo "~$OPENCLAW_USER")

# ============================================
# STAP 1: System Update + Dependencies
# ============================================
echo -e "${GREEN}[1/8] System update + dependencies...${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y \
    curl wget git \
    python3 python3-pip python3-venv \
    ffmpeg \
    jq ripgrep fd-find \
    tmux \
    build-essential \
    nginx \
    certbot python3-certbot-nginx \
    openssh-client

# ============================================
# STAP 2: Add user to sudoers (NOPASSWD)
# ============================================
echo -e "${GREEN}[2/8] Configuring sudo for $OPENCLAW_USER...${NC}"

# Add to sudo group
usermod -aG sudo "$OPENCLAW_USER"

# Add NOPASSWD sudoers entry
SUDOERS_FILE="/etc/sudoers.d/openclaw-$OPENCLAW_USER"
cat > "$SUDOERS_FILE" << EOF
# OpenClaw: allow $OPENCLAW_USER to run commands as root without password
$OPENCLAW_USER ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 "$SUDOERS_FILE"

# Validate sudoers file
if ! visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Invalid sudoers file, removing${NC}"
    rm -f "$SUDOERS_FILE"
    exit 1
fi
echo -e "${GREEN}  $OPENCLAW_USER can now use sudo without password${NC}"

# ============================================
# STAP 3: Install Node.js 22 LTS
# ============================================
echo -e "${GREEN}[3/8] Installing Node.js 22 LTS...${NC}"

if command -v node &>/dev/null && node -v | grep -q "v22"; then
    echo "  Node.js 22 already installed: $(node -v)"
else
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
    echo "  Node.js installed: $(node -v)"
fi

# Enable corepack for pnpm
corepack enable
echo "  pnpm enabled via corepack"

# ============================================
# STAP 4: Install Bun
# ============================================
echo -e "${GREEN}[4/8] Installing Bun...${NC}"

if command -v bun &>/dev/null; then
    echo "  Bun already installed: $(bun -v)"
else
    # Install as the user
    su - "$OPENCLAW_USER" -c 'curl -fsSL https://bun.sh/install | bash'
    echo "  Bun installed"
fi

# ============================================
# STAP 5: Install GitHub CLI
# ============================================
echo -e "${GREEN}[5/8] Installing GitHub CLI...${NC}"

if command -v gh &>/dev/null; then
    echo "  gh already installed: $(gh --version | head -1)"
else
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt-get update && apt-get install -y gh
    echo "  gh installed"
fi

# ============================================
# STAP 6: Create OpenClaw directories
# ============================================
echo -e "${GREEN}[6/8] Creating OpenClaw directories...${NC}"

mkdir -p /opt/openclaw
mkdir -p "$OPENCLAW_HOME/.openclaw"
mkdir -p /var/log/openclaw

# Set ownership
chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /opt/openclaw
chown -R "$OPENCLAW_USER:$OPENCLAW_USER" "$OPENCLAW_HOME/.openclaw"
chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /var/log/openclaw
chmod 700 "$OPENCLAW_HOME/.openclaw"

# ============================================
# STAP 7: DuckDNS (optional)
# ============================================
if [ -n "$DUCKDNS_TOKEN" ] && [ -n "$DUCKDNS_SUBDOMAIN" ]; then
    echo -e "${GREEN}[7/8] Configuring DuckDNS...${NC}"

    mkdir -p /opt/duckdns
    cat > /opt/duckdns/duck.sh << DUCKEOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /opt/duckdns/duck.log -K -
DUCKEOF
    chmod 700 /opt/duckdns/duck.sh
    /opt/duckdns/duck.sh

    if grep -q "OK" /opt/duckdns/duck.log 2>/dev/null; then
        echo -e "${GREEN}  DuckDNS update OK${NC}"
    else
        echo -e "${YELLOW}  DuckDNS result: $(cat /opt/duckdns/duck.log 2>/dev/null)${NC}"
    fi

    (crontab -l 2>/dev/null | grep -v duckdns; echo "*/5 * * * * /opt/duckdns/duck.sh >/dev/null 2>&1") | crontab -
else
    echo -e "${YELLOW}[7/8] Skipping DuckDNS (no token/subdomain set)${NC}"
fi

# ============================================
# STAP 8: Firewall
# ============================================
echo -e "${GREEN}[8/8] Configuring firewall...${NC}"

ufw allow 80/tcp comment 'HTTP for certbot' 2>/dev/null || true
ufw allow 443/tcp comment 'HTTPS for OpenClaw' 2>/dev/null || true
ufw reload 2>/dev/null || true

# ============================================
# STAP 9: Stop and remove Docker (optional)
# ============================================
echo ""
echo -e "${YELLOW}Docker cleanup:${NC}"
echo "  To stop the current Docker deployment:"
echo "    docker-compose -f /opt/openclaw/docker-compose.yml down"
echo "    docker rm -f openclaw-gateway 2>/dev/null"
echo ""
echo "  To fully remove Docker (optional):"
echo "    apt-get remove -y docker.io docker-ce docker-ce-cli containerd.io"
echo "    apt-get autoremove -y"
echo ""

# ============================================
# Done
# ============================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Native VPS Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Status:"
echo "  - Node.js: $(node -v 2>/dev/null || echo 'NOT INSTALLED')"
echo "  - pnpm: $(pnpm -v 2>/dev/null || echo 'NOT INSTALLED')"
echo "  - Nginx: $(nginx -v 2>&1 || echo 'NOT INSTALLED')"
echo "  - User: $OPENCLAW_USER (sudo NOPASSWD)"
echo "  - Install dir: /opt/openclaw"
echo "  - Config dir: $OPENCLAW_HOME/.openclaw"
echo "  - Log dir: /var/log/openclaw"
echo ""
echo "Next steps:"
echo "  1. Upload openclaw-source to /opt/openclaw/"
echo "  2. Run: cd /opt/openclaw && pnpm install && pnpm build"
echo "  3. Copy config: cp config.json5 $OPENCLAW_HOME/.openclaw/"
echo "  4. Copy .env: cp .env.openclaw /opt/openclaw/"
echo "  5. Install service: cp openclaw.service /etc/systemd/system/"
echo "  6. Start: systemctl enable openclaw && systemctl start openclaw"
echo ""
