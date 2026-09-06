#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika PRoot Ubuntu Hermes Agent Installer for Android (Termux)
# ==============================================================================
# Installs Hermes Agent inside an ultra-fast PRoot Ubuntu Linux container.
# Bypasses all Android wheel compilation & Rust build errors by using pre-compiled
# Linux aarch64 glibc wheels. Total install time: ~2 minutes.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash
#
# Or with API Key:
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash -s -- --api-key <YOUR_KEY> --provider <openrouter|nous|google>
# ==============================================================================

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}⚡ [Anamika] Hermes Agent OS (PRoot-Ubuntu High-Speed Installer)${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Parse optional arguments
USER_API_KEY=""
USER_PROVIDER="openrouter"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --api-key|-k)
            USER_API_KEY="$2"
            shift 2
            ;;
        --provider|-p)
            USER_PROVIDER="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Step 1: Prevent Termux CPU Sleep
echo -e "${YELLOW}[+] Step 1/4: Acquiring CPU Wakelock...${NC}"
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo -e "    ${GREEN}[✓] CPU Wakelock active.${NC}"
fi

# Step 2: Install PRoot-Distro on Termux
echo -e "${YELLOW}[+] Step 2/4: Installing PRoot-Distro & Core Linux Engine...${NC}"
pkg update -y -o Dpkg::Options::="--force-confold" || true
pkg install -y -o Dpkg::Options::="--force-confold" proot-distro curl termux-tools >/dev/null 2>&1 || pkg install -y proot-distro curl

# Step 3: Install / Setup Ubuntu Linux Container
echo -e "${YELLOW}[+] Step 3/4: Setting up Ubuntu Linux Environment...${NC}"
if ! proot-distro list | grep -E "ubuntu.*installed" >/dev/null 2>&1; then
    echo -e "    [*] Downloading clean Ubuntu Linux rootfs (~20MB)..."
    proot-distro install ubuntu
else
    echo -e "    ${GREEN}[✓] Ubuntu environment already present.${NC}"
fi

# Step 4: Install Hermes Agent inside Ubuntu (using native Linux aarch64 pre-built wheels)
echo -e "${YELLOW}[+] Step 4/4: Installing Hermes Agent OS with Pre-compiled Linux Wheels...${NC}"

proot-distro login ubuntu -- bash -s << UBUNTU_SCRIPT
set -e
export DEBIAN_FRONTEND=noninteractive

# Update apt & install essentials
apt update -y >/dev/null 2>&1
apt install -y curl git python3 python3-pip python3-venv ca-certificates sudo ripgrep >/dev/null 2>&1

# Run official Hermes installer (Fast Linux aarch64 path with UV)
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup

# Configure API Key if provided
if [ -n "$USER_API_KEY" ]; then
    mkdir -p /root/.hermes
    ENV_FILE="/root/.hermes/.env"
    touch "\$ENV_FILE"
    case "$USER_PROVIDER" in
        openrouter)
            echo "OPENROUTER_API_KEY=$USER_API_KEY" >> "\$ENV_FILE"
            ;;
        nous)
            echo "NOUS_API_KEY=$USER_API_KEY" >> "\$ENV_FILE"
            ;;
        google|gemini)
            echo "GEMINI_API_KEY=$USER_API_KEY" >> "\$ENV_FILE"
            ;;
        openai)
            echo "OPENAI_API_KEY=$USER_API_KEY" >> "\$ENV_FILE"
            ;;
        anthropic)
            echo "ANTHROPIC_API_KEY=$USER_API_KEY" >> "\$ENV_FILE"
            ;;
        *)
            echo "API_KEY=$USER_API_KEY" >> "\$ENV_FILE"
            ;;
    esac
    chmod 600 "\$ENV_FILE"
fi
UBUNTU_SCRIPT

# Step 5: Create Direct Termux Launchers
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
HERMES_LAUNCHER="$PREFIX_BIN/hermes"
HA_LAUNCHER="$PREFIX_BIN/ha"

cat << 'EOF' > "$HERMES_LAUNCHER"
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- hermes "$@"
EOF
chmod +x "$HERMES_LAUNCHER"

cat << 'EOF' > "$HA_LAUNCHER"
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- hermes "$@"
EOF
chmod +x "$HA_LAUNCHER"

# Setup aliases in .bashrc
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
if ! grep -q "alias ha=" "$BASHRC"; then
    cat << 'EOF' >> "$BASHRC"

# Hermes Agent Quick Aliases
alias ha='hermes'
alias ha-chat='hermes chat'
alias ha-model='hermes model'
alias ha-setup='hermes setup'
alias ha-doctor='hermes doctor'
alias ha-gateway='hermes gateway'
EOF
fi

echo ""
echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 [SUCCESS] Hermes Agent OS is Successfully Installed & Ready!${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""
echo -e "🚀 ${BOLD}How to Run Hermes:${NC}"
echo -e "  • Start Interactive Chat : ${CYAN}hermes${NC}  (or simply ${CYAN}ha${NC})"
echo -e "  • Setup Wizard           : ${CYAN}hermes setup${NC}"
echo -e "  • Change Model/Provider  : ${CYAN}hermes model${NC}"
echo -e "  • Environment Diagnostics: ${CYAN}hermes doctor${NC}"
echo ""
echo -e "💡 Simply type ${GREEN}hermes${NC} in Termux to start chatting!"
echo -e "${CYAN}====================================================================${NC}"
