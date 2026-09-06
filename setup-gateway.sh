#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika 1-Line Hermes Gateway Setup (Secure Telegram & Discord Connector)
# ==============================================================================
# Connects Hermes Agent to Telegram / Discord with STRICT User ID Whitelisting
# so that only YOU can talk to and control your Hermes bot.
#
# Usage (Secure Telegram with Whitelist):
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- telegram <BOT_TOKEN> <YOUR_USER_ID>
#
# Example:
#   bash setup-gateway.sh telegram 123456:ABC-DEF 9974870207
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

PLATFORM="${1:-telegram}"
BOT_TOKEN="$2"
ALLOWED_USER="${3:-}"

echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}⚡ [Anamika] Hermes Agent Gateway Secure Whitelisted Connector${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [ -z "$BOT_TOKEN" ]; then
    echo -e "${RED}[!] Error: Bot Token is required.${NC}"
    echo ""
    echo "Usage Examples:"
    echo "  bash setup-gateway.sh telegram <BOT_TOKEN> [YOUR_TELEGRAM_USER_ID]"
    echo "  bash setup-gateway.sh discord <BOT_TOKEN> [YOUR_DISCORD_USER_ID]"
    echo ""
    exit 1
fi

PLATFORM_LOWER=$(echo "$PLATFORM" | tr '[:upper:]' '[:lower:]')

echo -e "${YELLOW}[+] Step 1/3: Configuring Gateway for Platform: ${BOLD}${PLATFORM_LOWER}${NC}"

proot-distro login ubuntu -- bash -s << GATEWAY_SCRIPT
set -e
mkdir -p /root/.hermes/logs

ENV_FILE="/root/.hermes/.env"
touch "\$ENV_FILE"

# Clean old tokens and allowlists
sed -i '/TELEGRAM_BOT_TOKEN/d' "\$ENV_FILE" || true
sed -i '/TELEGRAM_ALLOWED_USERS/d' "\$ENV_FILE" || true
sed -i '/DISCORD_BOT_TOKEN/d' "\$ENV_FILE" || true
sed -i '/DISCORD_ALLOWED_USERS/d' "\$ENV_FILE" || true

if [ "$PLATFORM_LOWER" = "telegram" ]; then
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" >> "\$ENV_FILE"
    if [ -n "$ALLOWED_USER" ]; then
        echo "TELEGRAM_ALLOWED_USERS=$ALLOWED_USER" >> "\$ENV_FILE"
        echo "    [✓] Security Whitelist Activated: Only User ID '$ALLOWED_USER' is permitted."
    else
        echo "    [!] Warning: No User ID provided. Any Telegram user can talk to the bot."
    fi
elif [ "$PLATFORM_LOWER" = "discord" ]; then
    echo "DISCORD_BOT_TOKEN=$BOT_TOKEN" >> "\$ENV_FILE"
    if [ -n "$ALLOWED_USER" ]; then
        echo "DISCORD_ALLOWED_USERS=$ALLOWED_USER" >> "\$ENV_FILE"
    fi
fi
chmod 600 "\$ENV_FILE"

echo "    [✓] Bot credentials saved securely in ~/.hermes/.env"

# Kill old gateway processes
pkill -f "hermes gateway" || true
sleep 1

# Start Gateway in background
echo "[+] Step 2/3: Starting Hermes Gateway daemon..."
nohup hermes gateway > /root/.hermes/logs/gateway.log 2>&1 &
sleep 3

# Verify Gateway Status
if pgrep -f "hermes gateway" >/dev/null 2>&1; then
    echo "    [✓] Gateway daemon is ONLINE and running in background!"
else
    echo "    [!] Checking gateway output..."
    cat /root/.hermes/logs/gateway.log | tail -n 10 || true
fi
GATEWAY_SCRIPT

# Step 3: Add auto-start to Termux boot if termux-boot exists
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-hermes-gateway.sh
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
proot-distro login ubuntu -- bash -c 'nohup hermes gateway > /root/.hermes/logs/gateway.log 2>&1 &'
EOF
chmod +x ~/.termux/boot/start-hermes-gateway.sh

echo ""
echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 [SUCCESS] Hermes Agent is now SECURELY LIVE on ${PLATFORM_LOWER}!${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""
if [ -n "$ALLOWED_USER" ]; then
    echo -e "🔒 ${BOLD}Access Control:${NC} ${GREEN}LOCKED to User ID: $ALLOWED_USER${NC} (Strangers will be ignored automatically)."
else
    echo -e "⚠️  ${BOLD}Notice:${NC} To restrict access to yourself, find your numeric ID from @userinfobot and pass it as the 3rd argument."
fi
echo ""
echo -e "💬 ${BOLD}Start chatting on ${PLATFORM_LOWER}:${NC}"
echo -e "  Open your bot and send ${CYAN}/start${NC} or any message!"
echo -e "${CYAN}====================================================================${NC}"
