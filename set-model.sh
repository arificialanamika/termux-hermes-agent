#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika Custom Model Configurator (Zero-Secret-Hardcoding Architecture)
# ==============================================================================
# Usage:
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/set-model.sh | bash -s -- <API_KEY> [MODEL_NAME] [BASE_URL]
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

KEY_INPUT="$1"
MODEL_NAME="${2:-antigravity/claude-sonnet-4-6}"
BASE_URL="${3:-https://api.mandalworkforce.com/v1}"

if [ -z "$KEY_INPUT" ]; then
    echo -e "${RED}[!] Error: API Key is required as the first parameter.${NC}"
    echo ""
    echo "Usage:"
    echo "  curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/set-model.sh | bash -s -- <YOUR_API_KEY> [MODEL] [BASE_URL]"
    echo ""
    exit 1
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}⚡ [Anamika] Configuring Custom Model Engine for Hermes Agent${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "${YELLOW}[+] Target Model:${NC} ${BOLD}${MODEL_NAME}${NC}"
echo -e "${YELLOW}[+] Endpoint:${NC}     ${BOLD}${BASE_URL}${NC}"

proot-distro login ubuntu -- bash -s << CONFIG_SCRIPT
set -e
hermes config set model.provider custom
hermes config set model.base_url "$BASE_URL"
hermes config set model.default "$MODEL_NAME"
hermes config set model.api_key "$KEY_INPUT"

mkdir -p /root/.hermes
sed -i '/CUSTOM_API_KEY/d' /root/.hermes/.env 2>/dev/null || true
echo "CUSTOM_API_KEY=$KEY_INPUT" >> /root/.hermes/.env
chmod 600 /root/.hermes/.env 2>/dev/null || true

killall -9 "hermes" 2>/dev/null || true
sleep 1
nohup hermes gateway > /root/.hermes/logs/gateway.log 2>&1 &
CONFIG_SCRIPT

echo ""
echo -e "${GREEN}${BOLD}🎉 SUCCESS! Model successfully switched to ${MODEL_NAME}${NC}"
echo -e "${CYAN}====================================================================${NC}"
