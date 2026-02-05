#!/bin/bash
# setup-duckdns.sh
# DuckDNS Setup Script voor OpenClaw
# ==================================
#
# INSTRUCTIES:
# 1. Ga naar https://www.duckdns.org en login met GitHub/Google
# 2. Maak een subdomain aan (bijv: "myopenclaw" → myopenclaw.duckdns.org)
# 3. Kopieer je DuckDNS token van de website
# 4. Vul de variabelen hieronder in
# 5. Run dit script: sudo bash setup-duckdns.sh
#

# ===== VUL DEZE IN =====
DUCKDNS_SUBDOMAIN=""  # bijv: "myopenclaw"
DUCKDNS_TOKEN=""      # je token van duckdns.org
# =======================

# Validatie
if [ -z "$DUCKDNS_SUBDOMAIN" ] || [ -z "$DUCKDNS_TOKEN" ]; then
    echo "ERROR: Vul DUCKDNS_SUBDOMAIN en DUCKDNS_TOKEN in!"
    echo ""
    echo "Stappen:"
    echo "1. Ga naar https://www.duckdns.org"
    echo "2. Login met GitHub of Google"
    echo "3. Maak een subdomain aan"
    echo "4. Kopieer het token"
    echo "5. Edit dit script en vul de variabelen in"
    exit 1
fi

DOMAIN="${DUCKDNS_SUBDOMAIN}.duckdns.org"
echo "=== DuckDNS Setup voor ${DOMAIN} ==="

# 1. Maak DuckDNS update directory
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
    echo "✅ DuckDNS update successful!"
else
    echo "❌ DuckDNS update failed. Check your token."
    cat /opt/duckdns/duck.log
    exit 1
fi

# 3. Setup cron voor automatische updates (elke 5 minuten)
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
