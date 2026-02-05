#!/bin/bash
# setup-ssl.sh
# SSL Certificaat en Nginx Setup voor OpenClaw
# =============================================
#
# INSTRUCTIES:
# 1. Vul de variabelen hieronder in
# 2. Run NA vps-setup.sh en NA upload van files
# 3. Run als root: sudo bash setup-ssl.sh
#

set -e

# ===== VUL DEZE IN =====
DOMAIN=""  # bijv: "myopenclaw.duckdns.org"
EMAIL=""   # je email voor Let's Encrypt notificaties
# =======================

# Validatie
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "ERROR: Vul DOMAIN en EMAIL variabelen in!"
    echo ""
    echo "Benodigde variabelen:"
    echo "  DOMAIN - Je domein (bijv: myopenclaw.duckdns.org)"
    echo "  EMAIL  - Je email voor Let's Encrypt"
    exit 1
fi

echo "========================================="
echo "   SSL Setup voor ${DOMAIN}"
echo "========================================="
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Run als root (sudo bash setup-ssl.sh)"
    exit 1
fi

# Check of nginx config bestaat
if [ ! -f "/opt/openclaw/nginx-openclaw.conf" ]; then
    echo "ERROR: nginx-openclaw.conf niet gevonden in /opt/openclaw/"
    echo "Upload eerst alle files naar /opt/openclaw/"
    exit 1
fi

echo "[1/4] Tijdelijke nginx config voor certbot..."

# Stop nginx tijdelijk
systemctl stop nginx

echo "[2/4] SSL certificaat verkrijgen..."

# Verkrijg certificaat (standalone mode)
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email ${EMAIL} \
    --domain ${DOMAIN}

echo "[3/4] Nginx configureren..."

# Update domain in nginx config
sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" /opt/openclaw/nginx-openclaw.conf

# Kopieer OpenClaw nginx config
cp /opt/openclaw/nginx-openclaw.conf /etc/nginx/sites-available/openclaw

# Verwijder default site
rm -f /etc/nginx/sites-enabled/default

# Enable OpenClaw site
ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw

# Test nginx config
nginx -t

echo "[4/4] Nginx starten..."

systemctl start nginx
systemctl enable nginx

echo ""
echo "========================================="
echo "   SSL Setup Compleet!"
echo "========================================="
echo ""
echo "HTTPS actief op: https://${DOMAIN}"
echo ""
echo "Test met:"
echo "  curl -I https://${DOMAIN}/health"
echo ""
echo "Volgende stap: Docker images bouwen en starten"
echo "  cd /opt/openclaw"
echo "  docker compose up -d"
echo ""
