#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika Hermes Agent Native Daemon & Service Installer for Termux
# ==============================================================================
# Replaces broken systemd/dbus gateway service with Native Termux Daemon
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}⚡ [Anamika] Installing Native Hermes Gateway Daemon Manager for Termux${NC}"
echo -e "${CYAN}====================================================================${NC}"

PREFIX_BIN="/data/data/com.termux/files/usr/bin"
HA_GATEWAY="$PREFIX_BIN/ha-gateway"
HERMES_GATEWAY="$PREFIX_BIN/hermes-gateway"

# 1. Install tmux for bulletproof background persistence
if ! command -v tmux >/dev/null 2>&1; then
    echo -e "${YELLOW}[+] Installing tmux package...${NC}"
    pkg install -y tmux >/dev/null 2>&1 || true
fi

# 2. Acquire Termux wake lock so Android never kills the background daemon
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo -e "    [✓] Android Wake-Lock acquired."
fi

# 3. Create the native ha-gateway CLI binary
cat << 'EOF' > "$HA_GATEWAY"
#!/data/data/com.termux/files/usr/bin/bash
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

ACTION="${1:-status}"
TMUX_SESSION="hermes-gateway"

ensure_wake_lock() {
    if command -v termux-wake-lock >/dev/null 2>&1; then
        termux-wake-lock
    fi
}

start_gateway() {
    echo -e "${YELLOW}[+] Starting Hermes Gateway daemon...${NC}"
    ensure_wake_lock
    
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null || pgrep -f "hermes gateway" >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] Hermes Gateway is ALREADY RUNNING!${NC}"
        status_gateway
        return 0
    fi

    proot-distro login ubuntu -- mkdir -p /root/.hermes/logs
    
    if command -v tmux >/dev/null 2>&1; then
        tmux new-session -d -s "$TMUX_SESSION" "proot-distro login ubuntu -- hermes gateway 2>&1 | tee -a /root/.hermes/logs/gateway.log"
    else
        proot-distro login ubuntu -- bash -c 'nohup hermes gateway > /root/.hermes/logs/gateway.log 2>&1 &'
    fi

    sleep 2
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null || pgrep -f "hermes gateway" >/dev/null 2>&1; then
        echo -e "${GREEN}${BOLD}🚀 [SUCCESS] Hermes Gateway is ONLINE & Running in Background!${NC}"
    else
        echo -e "${RED}[!] Failed to start Gateway daemon. Checking logs:${NC}"
        proot-distro login ubuntu -- cat /root/.hermes/logs/gateway.log | tail -n 15 || true
    fi
}

stop_gateway() {
    echo -e "${YELLOW}[+] Stopping Hermes Gateway daemon...${NC}"
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
    fi
    proot-distro login ubuntu -- pkill -f "hermes gateway" 2>/dev/null || true
    killall -9 hermes 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}[✓] Hermes Gateway daemon STOPPED.${NC}"
}

status_gateway() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${GREEN}${BOLD}⚡ Hermes Agent Gateway Status (Termux Native)${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    
    RUNNING=0
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null || pgrep -f "hermes gateway" >/dev/null 2>&1; then
        RUNNING=1
    fi

    if [ "$RUNNING" -eq 1 ]; then
        echo -e "Status:     ${GREEN}${BOLD}● ONLINE (Running in Background)${NC}"
        echo -e "Wake-Lock:  ${GREEN}Active (Background execution guaranteed)${NC}"
        echo ""
        echo -e "${YELLOW}[Recent Logs (Last 10 lines)]:${NC}"
        proot-distro login ubuntu -- cat /root/.hermes/logs/gateway.log 2>/dev/null | tail -n 10 || echo "No logs yet."
    else
        echo -e "Status:     ${RED}${BOLD}○ STOPPED (Offline)${NC}"
        echo ""
        echo -e "To start:   ${CYAN}ha-gateway start${NC}"
    fi
    echo -e "${CYAN}====================================================================${NC}"
}

logs_gateway() {
    echo -e "${CYAN}Streaming live Gateway logs (Press Ctrl+C to exit)...${NC}"
    proot-distro login ubuntu -- tail -f /root/.hermes/logs/gateway.log
}

attach_gateway() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux attach -t "$TMUX_SESSION"
    else
        echo -e "${RED}[!] No active tmux session found. Start gateway first with: ha-gateway start${NC}"
    fi
}

case "$ACTION" in
    start|up)
        start_gateway
        ;;
    stop|down)
        stop_gateway
        ;;
    restart|reload)
        stop_gateway
        sleep 1
        start_gateway
        ;;
    status|check)
        status_gateway
        ;;
    logs|log)
        logs_gateway
        ;;
    attach|console)
        attach_gateway
        ;;
    *)
        echo "Usage: ha-gateway {start|stop|restart|status|logs|attach}"
        exit 1
        ;;
esac
EOF
chmod +x "$HA_GATEWAY"
cp "$HA_GATEWAY" "$HERMES_GATEWAY"
chmod +x "$HERMES_GATEWAY"

# 4. Update ~/.bashrc aliases
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
sed -i '/alias ha-gateway=/d' "$BASHRC" 2>/dev/null || true
echo "alias ha-gateway='$HA_GATEWAY'" >> "$BASHRC"

# 5. Setup auto-boot script
mkdir -p ~/.termux/boot
cat << 'EOF' > ~/.termux/boot/start-hermes-gateway.sh
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
/data/data/com.termux/files/usr/bin/ha-gateway start
EOF
chmod +x ~/.termux/boot/start-hermes-gateway.sh

# 6. Start the gateway now!
"$HA_GATEWAY" restart

echo ""
echo -e "${GREEN}${BOLD}🎉 Native Gateway Service Installed & Started!${NC}"
echo -e "👉 Use ${CYAN}ha-gateway status${NC} to check status anytime."
echo -e "👉 Use ${CYAN}ha-gateway logs${NC} to view live logs."
echo -e "${CYAN}====================================================================${NC}"
