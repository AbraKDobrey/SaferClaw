#!/bin/bash
# setup-ssl.sh
# SSL Certificate and Nginx Setup for OpenClaw
# =============================================
#
# INSTRUCTIONS:
# 1. Fill in the variables below
# 2. Run AFTER vps-setup.sh and AFTER uploading files
# 3. Run as root: sudo bash setup-ssl.sh
#

set -e

# ===== FILL THESE IN =====
DOMAIN=""  # e.g.: "myopenclaw.duckdns.org"
EMAIL=""   # your email for Let's Encrypt notifications
# =========================

# Validation
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "ERROR: Fill in the DOMAIN and EMAIL variables!"
    echo ""
    echo "Required variables:"
    echo "  DOMAIN - Your domain (e.g.: myopenclaw.duckdns.org)"
    echo "  EMAIL  - Your email for Let's Encrypt"
    exit 1
fi

echo "========================================="
echo "   SSL Setup for ${DOMAIN}"
echo "========================================="
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Run as root (sudo bash setup-ssl.sh)"
    exit 1
fi

# Check if nginx config exists
if [ ! -f "/opt/openclaw/nginx-openclaw.conf" ]; then
    echo "ERROR: nginx-openclaw.conf not found in /opt/openclaw/"
    echo "Run install-openclaw.sh first to copy all files to /opt/openclaw/"
    exit 1
fi

echo "[1/4] Temporary nginx config for certbot..."

# Stop nginx temporarily
systemctl stop nginx

echo "[2/4] Obtaining SSL certificate..."

# Obtain certificate (standalone mode)
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email ${EMAIL} \
    --domain ${DOMAIN}

echo "[3/4] Configuring Nginx..."

# Update domain in nginx config
sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" /opt/openclaw/nginx-openclaw.conf

# Copy OpenClaw nginx config
cp /opt/openclaw/nginx-openclaw.conf /etc/nginx/sites-available/openclaw

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Enable OpenClaw site
ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw

# Test nginx config
nginx -t

echo "[4/4] Starting Nginx..."

systemctl start nginx
systemctl enable nginx

echo ""
echo "========================================="
echo "   SSL Setup Complete!"
echo "========================================="
echo ""
echo "HTTPS active at: https://${DOMAIN}"
echo ""
echo "Test with:"
echo "  curl -s http://localhost:47832/health"
echo ""
echo "Next step: Start the OpenClaw service"
echo "  sudo systemctl start openclaw"
echo "  sudo systemctl enable openclaw"
echo ""
