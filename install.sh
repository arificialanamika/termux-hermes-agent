#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika One-Line Hermes Agent Installer for Android (Termux)
# ==============================================================================
# Completely automated 1-command installer for Hermes Agent OS on Android/Termux.
# Configures native Android toolchains (Clang, Rust, Python 3.11+, Make, FFI, SSL),
# installs Hermes Agent, sets up CPU Wakelock & PATHs, and configures quick aliases.
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
echo -e "${GREEN}${BOLD}⚡ [Anamika] Autonomous Hermes Agent Installer for Android (Termux)${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Parse optional arguments
USER_API_KEY=""
USER_PROVIDER="openrouter"
USER_MODEL="hermes-3-llama-3.1-8b"

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
        --model|-m)
            USER_MODEL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Step 1: Prevent Termux CPU Sleep during compilation
echo -e "${YELLOW}[+] Step 1/5: Acquiring CPU Wakelock...${NC}"
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo -e "    ${GREEN}[✓] CPU Wakelock active.${NC}"
fi

# Step 2: Install Core Native Build Dependencies
echo -e "${YELLOW}[+] Step 2/5: Installing Android Toolchains & Build Dependencies...${NC}"
pkg update -y -o Dpkg::Options::="--force-confold" || true

PACKAGES=(
    python
    git
    clang
    rust
    make
    pkg-config
    libffi
    openssl
    ca-certificates
    curl
    termux-tools
    ripgrep
    nodejs-lts
    tar
)

for pkg in "${PACKAGES[@]}"; do
    echo -e "    [*] Installing $pkg..."
    pkg install -y -o Dpkg::Options::="--force-confold" "$pkg" >/dev/null 2>&1 || pkg install -y "$pkg"
done
echo -e "    ${GREEN}[✓] Android C/Rust/Python toolchain ready.${NC}"

# Step 3: Setup Android CFLAGS & API Level
echo -e "${YELLOW}[+] Step 3/5: Configuring Android Native Compilation Flags...${NC}"
export CFLAGS="-Wno-error=incompatible-function-pointer-types"
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk 2>/dev/null || echo 24)"
export UV_NO_CONFIG=1

# Step 4: Run Official Hermes Installer in Automated Mode
echo -e "${YELLOW}[+] Step 4/5: Downloading & Installing Hermes Agent OS...${NC}"
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup

# Step 5: Configure Shell Aliases and Convenience Launchers
echo -e "${YELLOW}[+] Step 5/5: Configuring Shell Helpers & PATHs...${NC}"
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
HERMES_BIN="$HOME/.local/bin/hermes"

if [ -f "$HERMES_BIN" ] && [ ! -f "$PREFIX_BIN/hermes" ]; then
    ln -sf "$HERMES_BIN" "$PREFIX_BIN/hermes"
fi

# Ensure ~/.bashrc has aliases
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

# If API key was passed, pre-configure it
if [ -n "$USER_API_KEY" ]; then
    echo -e "${YELLOW}[*] Configuring API Provider ($USER_PROVIDER)...${NC}"
    mkdir -p "$HOME/.hermes"
    
    # Save Key to .env
    ENV_FILE="$HOME/.hermes/.env"
    touch "$ENV_FILE"
    
    case "$USER_PROVIDER" in
        openrouter)
            echo "OPENROUTER_API_KEY=$USER_API_KEY" >> "$ENV_FILE"
            ;;
        nous)
            echo "NOUS_API_KEY=$USER_API_KEY" >> "$ENV_FILE"
            ;;
        google|gemini)
            echo "GEMINI_API_KEY=$USER_API_KEY" >> "$ENV_FILE"
            ;;
        openai)
            echo "OPENAI_API_KEY=$USER_API_KEY" >> "$ENV_FILE"
            ;;
        anthropic)
            echo "ANTHROPIC_API_KEY=$USER_API_KEY" >> "$ENV_FILE"
            ;;
        *)
            echo "API_KEY=$USER_API_KEY" >> "$ENV_FILE"
            ;;
    esac
    chmod 600 "$ENV_FILE"
    echo -e "    ${GREEN}[✓] API Key saved to ~/.hermes/.env${NC}"
fi

echo ""
echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 [SUCCESS] Hermes Agent OS is Successfully Installed on Android!${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""
echo -e "🚀 ${BOLD}Quick Start Commands:${NC}"
echo -e "  1. Start Interactive Chat : ${CYAN}hermes${NC} (or ${CYAN}ha${NC})"
echo -e "  2. Quick Setup Wizard     : ${CYAN}hermes setup${NC}"
echo -e "  3. Select Model/Provider  : ${CYAN}hermes model${NC}"
echo -e "  4. System Health Check    : ${CYAN}hermes doctor${NC}"
echo ""
echo -e "💡 To start chatting right now, simply run:"
echo -e "  ${GREEN}hermes${NC}"
echo -e "${CYAN}====================================================================${NC}"
