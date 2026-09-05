#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# ⚡ Anamika Bulletproof Hermes Agent Installer for Android (Termux)
# ==============================================================================
# 1-Click Native Installer for Hermes Agent OS on Android/Termux.
# Fixes Android Rust/Maturin build bottlenecks, configures native C toolchains,
# installs tested Termux profile, sets up CPU Wakelock & CLI Launchers.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}====================================================================${NC}"
echo -e "${GREEN}${BOLD}⚡ [Anamika] Autonomous Hermes Agent OS Installer (Termux Android)${NC}"
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

# Step 1: Prevent Termux CPU Sleep during compilation
echo -e "${YELLOW}[+] Step 1/6: Acquiring CPU Wakelock...${NC}"
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo -e "    ${GREEN}[✓] CPU Wakelock active (prevents sleep during background runs).${NC}"
fi

# Step 2: Install Core Native Android Toolchains & Dependencies
echo -e "${YELLOW}[+] Step 2/6: Installing Android Native Toolchains & Pre-compiled Packages...${NC}"
pkg update -y -o Dpkg::Options::="--force-confold" || true

# Try adding TUR repo for fast pre-compiled ARM wheels
pkg install -y -o Dpkg::Options::="--force-confold" tur-repo >/dev/null 2>&1 || true

CORE_PKGS=(
    python
    git
    clang
    rust
    maturin
    binutils
    lld
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

for pkg in "${CORE_PKGS[@]}"; do
    echo -e "    [*] Installing $pkg..."
    pkg install -y -o Dpkg::Options::="--force-confold" "$pkg" >/dev/null 2>&1 || pkg install -y "$pkg" >/dev/null 2>&1 || true
done
echo -e "    ${GREEN}[✓] Core build packages installed.${NC}"

# Step 3: Configure Target Architecture & Compiler Flags
echo -e "${YELLOW}[+] Step 3/6: Configuring Android Architecture & Compiler Flags...${NC}"
ARCH="$(uname -m)"
if [ "$ARCH" = "aarch64" ]; then
    export CARGO_BUILD_TARGET="aarch64-linux-android"
elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "arm" ]; then
    export CARGO_BUILD_TARGET="armv7-linux-androideabi"
elif [ "$ARCH" = "x86_64" ]; then
    export CARGO_BUILD_TARGET="x86_64-linux-android"
fi

export CC=clang
export CXX=clang++
export CFLAGS="-Wno-error=incompatible-function-pointer-types"
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk 2>/dev/null || echo 24)"
export UV_NO_CONFIG=1

echo -e "    ${GREEN}[✓] Target: $CARGO_BUILD_TARGET (API Level: $ANDROID_API_LEVEL)${NC}"

# Step 4: Clone / Update Hermes Agent Source Repository
echo -e "${YELLOW}[+] Step 4/6: Fetching Hermes Agent Source Code...${NC}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
INSTALL_DIR="$HERMES_HOME/hermes-agent"
mkdir -p "$HERMES_HOME"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "    [*] Updating existing Hermes Agent checkout..."
    cd "$INSTALL_DIR"
    git fetch origin
    git reset --hard origin/main || git pull
else
    echo -e "    [*] Cloning Hermes Agent repository..."
    rm -rf "$INSTALL_DIR"
    git clone https://github.com/NousResearch/hermes-agent.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Step 5: Setup Python Virtual Environment & Install Tested Termux Profile
echo -e "${YELLOW}[+] Step 5/6: Building Python Virtual Environment & Installing Dependencies...${NC}"
rm -rf venv
python3 -m venv venv
VENV_PYTHON="$INSTALL_DIR/venv/bin/python"
VENV_PIP="$INSTALL_DIR/venv/bin/pip"

"$VENV_PIP" install --upgrade pip setuptools wheel >/dev/null 2>&1 || true

# Prebuild psutil android compatibility shim
if [ -f "$INSTALL_DIR/scripts/install_psutil_android.py" ]; then
    echo -e "    [*] Prebuilding psutil Android shim..."
    "$VENV_PYTHON" "$INSTALL_DIR/scripts/install_psutil_android.py" --pip "$VENV_PIP" >/dev/null 2>&1 || true
fi

# Install stable Termux profile (avoids unsupported native scraper wheels)
echo -e "    [*] Installing Hermes Agent packages (Termux profile)..."
if [ -f "constraints-termux.txt" ]; then
    "$VENV_PIP" install -e '.[termux]' -c constraints-termux.txt || \
    "$VENV_PIP" install -e '.' -c constraints-termux.txt || \
    "$VENV_PIP" install -e '.'
else
    "$VENV_PIP" install -e '.'
fi

echo -e "    ${GREEN}[✓] Hermes Agent core & dependencies installed successfully.${NC}"

# Step 6: Create Launchers and Shell Aliases
echo -e "${YELLOW}[+] Step 6/6: Configuring CLI Launchers & Aliases...${NC}"
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
HERMES_LAUNCHER="$PREFIX_BIN/hermes"

cat << 'EOF' > "$HERMES_LAUNCHER"
#!/data/data/com.termux/files/usr/bin/bash
HERMES_DIR="$HOME/.hermes/hermes-agent"
if [ -x "$HERMES_DIR/venv/bin/hermes" ]; then
    exec "$HERMES_DIR/venv/bin/hermes" "$@"
else
    echo "[-] Hermes binary not found at $HERMES_DIR/venv/bin/hermes"
    exit 1
fi
EOF
chmod +x "$HERMES_LAUNCHER"

# Also link hermes-acp if exists
if [ -f "$INSTALL_DIR/venv/bin/hermes-acp" ]; then
    ln -sf "$INSTALL_DIR/venv/bin/hermes-acp" "$PREFIX_BIN/hermes-acp"
fi

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

# Configure API Key if passed
if [ -n "$USER_API_KEY" ]; then
    echo -e "${YELLOW}[*] Configuring API Provider ($USER_PROVIDER)...${NC}"
    ENV_FILE="$HERMES_HOME/.env"
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
echo -e "${GREEN}${BOLD}🎉 [SUCCESS] Hermes Agent OS is Ready on Your Android Phone!${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""
echo -e "🚀 ${BOLD}How to Run Hermes:${NC}"
echo -e "  • Start Interactive Chat : ${CYAN}hermes${NC}  (or simply ${CYAN}ha${NC})"
echo -e "  • Setup Wizard           : ${CYAN}hermes setup${NC}"
echo -e "  • Pick Model / Provider  : ${CYAN}hermes model${NC}"
echo -e "  • Environment Diagnostics: ${CYAN}hermes doctor${NC}"
echo ""
echo -e "💡 Run ${GREEN}hermes${NC} to start pair programming on your phone!"
echo -e "${CYAN}====================================================================${NC}"
