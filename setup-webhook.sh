#!/bin/bash
# setup-webhook.sh
# Telegram Webhook Configuratie
# =============================
#
# INSTRUCTIES:
# 1. Vul de variabelen hieronder in
# 2. Run dit NADAT Docker draait en SSL werkt
#

# ===== VUL DEZE IN =====
DOMAIN=""           # bijv: "myopenclaw.duckdns.org"
BOT_TOKEN=""        # van @BotFather
WEBHOOK_SECRET=""   # genereer met: openssl rand -hex 16
# =======================

# Validatie
if [ -z "$DOMAIN" ] || [ -z "$BOT_TOKEN" ] || [ -z "$WEBHOOK_SECRET" ]; then
    echo "ERROR: Vul alle variabelen in!"
    echo ""
    echo "Benodigde variabelen:"
    echo "  DOMAIN         - Je domein (bijv: myopenclaw.duckdns.org)"
    echo "  BOT_TOKEN      - Telegram bot token van @BotFather"
    echo "  WEBHOOK_SECRET - Genereer met: openssl rand -hex 16"
    exit 1
fi

WEBHOOK_URL="https://${DOMAIN}/tg/webhook"

echo "========================================="
echo "   Telegram Webhook Setup"
echo "========================================="
echo ""
echo "Webhook URL: ${WEBHOOK_URL}"
echo ""

# 1. Verwijder oude webhook (indien aanwezig)
echo "[1/3] Oude webhook verwijderen..."
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/deleteWebhook" | jq .

# 2. Set nieuwe webhook
echo ""
echo "[2/3] Nieuwe webhook instellen..."
RESULT=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook" \
    -d "url=${WEBHOOK_URL}" \
    -d "secret_token=${WEBHOOK_SECRET}" \
    -d "allowed_updates=[\"message\",\"edited_message\",\"callback_query\"]")

echo "${RESULT}" | jq .

# 3. Verifieer
echo ""
echo "[3/3] Webhook info verifiëren..."
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" | jq .

echo ""
echo "========================================="
echo "   Webhook Setup Compleet!"
echo "========================================="
echo ""
echo "Test de bot door een bericht te sturen in Telegram"
echo ""
