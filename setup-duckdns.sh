#!/bin/bash
# setup-duckdns.sh
# DuckDNS Setup Script for OpenClaw
# ==================================
#
# INSTRUCTIONS:
# 1. Go to https://www.duckdns.org and log in with GitHub/Google
# 2. Create a subdomain (e.g.: "myopenclaw" -> myopenclaw.duckdns.org)
# 3. Copy your DuckDNS token from the website
# 4. Fill in the variables below
# 5. Run this script: sudo bash setup-duckdns.sh
#

# ===== FILL THESE IN =====
DUCKDNS_SUBDOMAIN=""  # e.g.: "myopenclaw"
DUCKDNS_TOKEN=""      # your token from duckdns.org
# =========================

# Validation
if [ -z "$DUCKDNS_SUBDOMAIN" ] || [ -z "$DUCKDNS_TOKEN" ]; then
    echo "ERROR: Fill in DUCKDNS_SUBDOMAIN and DUCKDNS_TOKEN!"
    echo ""
    echo "Steps:"
    echo "1. Go to https://www.duckdns.org"
    echo "2. Log in with GitHub or Google"
    echo "3. Create a subdomain"
    echo "4. Copy the token"
    echo "5. Edit this script and fill in the variables"
    exit 1
fi

DOMAIN="${DUCKDNS_SUBDOMAIN}.duckdns.org"
echo "=== DuckDNS Setup for ${DOMAIN} ==="

# 1. Create DuckDNS update directory
echo "[1/4] Creating DuckDNS directory..."
mkdir -p /opt/duckdns
cat > /opt/duckdns/duck.sh << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /opt/duckdns/duck.log -K -
EOF
chmod 700 /opt/duckdns/duck.sh

# 2. Test DuckDNS update
echo "[2/4] Testing DuckDNS update..."
/opt/duckdns/duck.sh
if grep -q "OK" /opt/duckdns/duck.log; then
    echo "DuckDNS update successful!"
else
    echo "DuckDNS update failed. Check your token."
    cat /opt/duckdns/duck.log
    exit 1
fi

# 3. Setup cron for automatic updates (every 5 minutes)
echo "[3/4] Setting up cron job..."
(crontab -l 2>/dev/null | grep -v duckdns; echo "*/5 * * * * /opt/duckdns/duck.sh >/dev/null 2>&1") | crontab -

# 4. Output info
echo "[4/4] Done!"
echo ""
echo "=== DuckDNS Configured ==="
echo "Domain: ${DOMAIN}"
echo "IP updates: Every 5 minutes via cron"
echo ""
echo "Next step: Get SSL certificate with:"
echo "  certbot certonly --standalone -d ${DOMAIN}"
echo ""
echo "Or if nginx is already running:"
echo "  certbot --nginx -d ${DOMAIN}"
