#!/bin/bash
# setup-webhook.sh
# Telegram Webhook Configuration
# ===============================
#
# INSTRUCTIONS:
# 1. Fill in the variables below
# 2. Run this AFTER the OpenClaw service is running and SSL is working
#

# ===== FILL THESE IN =====
DOMAIN=""           # e.g.: "myopenclaw.duckdns.org"
BOT_TOKEN=""        # from @BotFather
WEBHOOK_SECRET=""   # generate with: openssl rand -hex 16
# =========================

# Validation
if [ -z "$DOMAIN" ] || [ -z "$BOT_TOKEN" ] || [ -z "$WEBHOOK_SECRET" ]; then
    echo "ERROR: Fill in all variables!"
    echo ""
    echo "Required variables:"
    echo "  DOMAIN         - Your domain (e.g.: myopenclaw.duckdns.org)"
    echo "  BOT_TOKEN      - Telegram bot token from @BotFather"
    echo "  WEBHOOK_SECRET - Generate with: openssl rand -hex 16"
    exit 1
fi

WEBHOOK_URL="https://${DOMAIN}/tg/webhook"

echo "========================================="
echo "   Telegram Webhook Setup"
echo "========================================="
echo ""
echo "Webhook URL: ${WEBHOOK_URL}"
echo ""

# 1. Remove old webhook (if present)
echo "[1/3] Removing old webhook..."
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/deleteWebhook" | jq .

# 2. Set new webhook
echo ""
echo "[2/3] Setting new webhook..."
RESULT=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook" \
    -d "url=${WEBHOOK_URL}" \
    -d "secret_token=${WEBHOOK_SECRET}" \
    -d "allowed_updates=[\"message\",\"edited_message\",\"callback_query\"]")

echo "${RESULT}" | jq .

# 3. Verify
echo ""
echo "[3/3] Verifying webhook info..."
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" | jq .

echo ""
echo "========================================="
echo "   Webhook Setup Complete!"
echo "========================================="
echo ""
echo "Test the bot by sending a message in Telegram"
echo ""
