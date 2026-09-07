#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika 1-Line Hermes Gateway Setup (Secure Telegram & Discord Connector)
# ==============================================================================
# Connects Hermes Agent to Telegram / Discord with STRICT User ID Whitelisting
# and Native Termux Daemon Management (Zero systemd/dbus errors).
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- telegram <BOT_TOKEN> <YOUR_USER_ID>
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

echo -e "${YELLOW}[+] Step 1/3: Configuring Credentials for Platform: ${BOLD}${PLATFORM_LOWER}${NC}"

proot-distro login ubuntu -- bash -s << GATEWAY_SCRIPT
set -e
mkdir -p /root/.hermes/logs

ENV_FILE="/root/.hermes/.env"
touch "\$ENV_FILE"

# Clean old tokens and allowlists
sed -i '/TELEGRAM_BOT_TOKEN/d' "\$ENV_FILE" 2>/dev/null || true
sed -i '/TELEGRAM_ALLOWED_USERS/d' "\$ENV_FILE" 2>/dev/null || true
sed -i '/DISCORD_BOT_TOKEN/d' "\$ENV_FILE" 2>/dev/null || true
sed -i '/DISCORD_ALLOWED_USERS/d' "\$ENV_FILE" 2>/dev/null || true

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
GATEWAY_SCRIPT

# Step 2: Install Native Termux Daemon Manager
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
HA_GATEWAY="$PREFIX_BIN/ha-gateway"

if ! command -v tmux >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing tmux package...${NC}"
    pkg install -y tmux >/dev/null 2>&1 || true
fi

cat << 'EOF' > "$HA_GATEWAY"
#!/data/data/com.termux/files/usr/bin/bash
ACTION="${1:-status}"
TMUX_SESSION="hermes-gateway"

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi

case "$ACTION" in
    start|up)
        if tmux has-session -t "$TMUX_SESSION" 2>/dev/null || pgrep -f "hermes gateway" >/dev/null 2>&1; then
            echo "[✓] Hermes Gateway is already running."
            exit 0
        fi
        proot-distro login ubuntu -- mkdir -p /root/.hermes/logs
        if command -v tmux >/dev/null 2>&1; then
            tmux new-session -d -s "$TMUX_SESSION" "proot-distro login ubuntu -- hermes gateway 2>&1 | tee -a /root/.hermes/logs/gateway.log"
        else
            proot-distro login ubuntu -- bash -c 'nohup hermes gateway > /root/.hermes/logs/gateway.log 2>&1 &'
        fi
        sleep 2
        echo "[✓] Hermes Gateway started in background."
        ;;
    stop|down)
        tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
        proot-distro login ubuntu -- pkill -f "hermes gateway" 2>/dev/null || true
        killall -9 hermes 2>/dev/null || true
        echo "[✓] Hermes Gateway stopped."
        ;;
    restart|reload)
        tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
        proot-distro login ubuntu -- pkill -f "hermes gateway" 2>/dev/null || true
        killall -9 hermes 2>/dev/null || true
        sleep 1
        proot-distro login ubuntu -- mkdir -p /root/.hermes/logs
        if command -v tmux >/dev/null 2>&1; then
            tmux new-session -d -s "$TMUX_SESSION" "proot-distro login ubuntu -- hermes gateway 2>&1 | tee -a /root/.hermes/logs/gateway.log"
        else
            proot-distro login ubuntu -- bash -c 'nohup hermes gateway > /root/.hermes/logs/gateway.log 2>&1 &'
        fi
        sleep 2
        echo "[✓] Hermes Gateway restarted."
        ;;
    status|check)
        if tmux has-session -t "$TMUX_SESSION" 2>/dev/null || pgrep -f "hermes gateway" >/dev/null 2>&1; then
            echo "● ONLINE (Running in background)"
            proot-distro login ubuntu -- cat /root/.hermes/logs/gateway.log 2>/dev/null | tail -n 10 || true
        else
            echo "○ STOPPED (Offline)"
        fi
        ;;
    logs|log)
        proot-distro login ubuntu -- tail -f /root/.hermes/logs/gateway.log
        ;;
    attach|console)
        tmux attach -t "$TMUX_SESSION"
        ;;
    *)
        echo "Usage: ha-gateway {start|stop|restart|status|logs|attach}"
        exit 1
        ;;
esac
EOF
chmod +x "$HA_GATEWAY"

# Step 3: Launch Gateway via Native Manager
echo -e "${YELLOW}[+] Step 2/3: Launching Hermes Gateway via Native Daemon...${NC}"
"$HA_GATEWAY" restart

# Step 4: Add auto-start to Termux boot
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-hermes-gateway.sh
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
/data/data/com.termux/files/usr/bin/ha-gateway start
EOF
chmod +x ~/.termux/boot/start-hermes-gateway.sh

echo ""
echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 [SUCCESS] Hermes Agent is now SECURELY LIVE on ${PLATFORM_LOWER}!${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""
echo -e "🚀 ${BOLD}Gateway Commands in Termux:${NC}"
echo -e "  • Check status : ${CYAN}ha-gateway status${NC}"
echo -e "  • View logs    : ${CYAN}ha-gateway logs${NC}"
echo -e "  • Stop gateway : ${CYAN}ha-gateway stop${NC}"
echo -e "  • Restart      : ${CYAN}ha-gateway restart${NC}"
echo -e "${CYAN}====================================================================${NC}"
