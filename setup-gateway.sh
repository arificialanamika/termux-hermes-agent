#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika 1-Line Hermes Gateway Setup (Telegram & Discord Bot Connector)
# ==============================================================================
# Automatically connects Hermes Agent to Telegram or Discord in 1 command,
# saves the bot token, enables gateway platforms, and starts the background daemon.
#
# Usage (Telegram):
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- telegram <TELEGRAM_BOT_TOKEN>
#
# Usage (Discord):
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- discord <DISCORD_BOT_TOKEN>
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

echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}⚡ [Anamika] Hermes Agent Gateway 1-Click Bot Connector${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [ -z "$BOT_TOKEN" ]; then
    echo -e "${RED}[!] Error: Bot Token is required.${NC}"
    echo ""
    echo "Usage Examples:"
    echo "  bash setup-gateway.sh telegram 123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ"
    echo "  bash setup-gateway.sh discord MTA5ODc2NTQzMjEwOTg3NjU0.XXXXXX.YYYYYY"
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

# Remove old token for platform
sed -i '/TELEGRAM_BOT_TOKEN/d' "\$ENV_FILE" || true
sed -i '/DISCORD_BOT_TOKEN/d' "\$ENV_FILE" || true

if [ "$PLATFORM_LOWER" = "telegram" ]; then
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" >> "\$ENV_FILE"
elif [ "$PLATFORM_LOWER" = "discord" ]; then
    echo "DISCORD_BOT_TOKEN=$BOT_TOKEN" >> "\$ENV_FILE"
fi
chmod 600 "\$ENV_FILE"

echo "    [✓] Bot token stored in ~/.hermes/.env"

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
echo -e "${GREEN}${BOLD}🎉 [SUCCESS] Hermes Agent is now LIVE on ${PLATFORM_LOWER}!${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""
echo -e "💬 ${BOLD}How to Chat with your Bot:${NC}"
if [ "$PLATFORM_LOWER" = "telegram" ]; then
    echo -e "  1. Open Telegram on your phone."
    echo -e "  2. Search for your bot handle."
    echo -e "  3. Click ${CYAN}/start${NC} and start talking (Text or Voice notes)!"
elif [ "$PLATFORM_LOWER" = "discord" ]; then
    echo -e "  1. Invite your bot to your Discord Server."
    echo -e "  2. Mention your bot or send a DM to start interacting!"
fi
echo ""
echo -e "📊 To check gateway logs anytime in Termux:"
echo -e "  ${CYAN}proot-distro login ubuntu -- tail -f /root/.hermes/logs/gateway.log${NC}"
echo -e "${CYAN}====================================================================${NC}"
