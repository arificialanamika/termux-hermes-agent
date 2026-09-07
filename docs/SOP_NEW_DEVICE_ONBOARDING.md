# SOP: New Android / Termux Device Onboarding
**Standard Operating Procedure for Autonomous Hermes Agent OS & Mobile Proxy Fleet Setup**

- **Document ID:** `SOP-DEV-001`
- **Version:** `1.0.0`
- **Author:** Anamika (AI Systems Architect)
- **Review Date:** Bi-weekly
- **Target OS:** Android 10+ (Termux ARM64)

---

## 1. Purpose & Business Value
To establish a fully standardized, zero-friction, repeatable deployment pipeline for onboarding new Android devices (smartphones, tablets) into the **Autonomous Hermes Agent OS** and **Mobile Proxy Fleet**. 

When Anant states *"New device add karna hai: <DeviceName>"*, Anamika executes this SOP end-to-end to create dedicated bot identities, configure high-intelligence model routing (Claude Sonnet 4.6), establish daemonized gateway persistence, and allocate mobile residential proxy ports.

---

## 2. Prerequisites & Dependencies
- **VPS Infrastructure:**
  - IP: `77.37.44.130`
  - SSH Webhook Key Store: `/opt/MyFiles/Projects/AnamikaPC/data/sms/authorized_proxy_keys.txt`
  - MandalWorkforce Model API Endpoint: `https://api.mandalworkforce.com/v1`
  - Default Model: `antigravity/claude-sonnet-4-6`
- **Telegram Engine:**
  - Active Telethon Session in `/opt/MyFiles/Projects/HermesAgent/telegram_bot_mgmt`
  - Whitelisted Telegram User ID: `7361027380` (Anant)
- **Android Target Device:**
  - Termux installed from F-Droid.
  - Internet connection (WiFi or 4G/5G SIM).

---

## 3. Workflow Steps (Autonomous Execution)

### Step 1: Autonomous Telegram Bot Creation
Anamika calls `telegram_bot_mgmt` CLI with the new device name:
```bash
python3 -m telegram_bot_mgmt.cli create-bot "<DeviceName>Hermes" "<devicename>_hermes_bot" --project "<DeviceName>"
```
- Retrieves raw token from encrypted store `cred_tg_<bot_id>`.
- Validates bot status via `https://api.telegram.org/bot<token>/getMe`.
- Whitelist locked to Anant's User ID: `7361027380`.

### Step 2: Generate 1-Line Termux Deployment Pipeline
Anamika outputs the structured 4-step deployment suite to Anant:

1. **Install Hermes Agent OS (2 Minutes):**
   ```bash
   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash
   ```
2. **Configure Custom Model (Claude Sonnet 4.6):**
   ```bash
   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/set-model.sh | bash -s -- <MANDAL_KEY>
   ```
3. **Connect Telegram Gateway (Native Daemon + Auto-Boot):**
   ```bash
   curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- telegram <BOT_TOKEN> 7361027380
   ```
4. **Deploy Mobile Proxy Fleet Node (Optional for 4G/5G SIM devices):**
   ```bash
   curl -sSL https://raw.githubusercontent.com/arificialanamika/mobile-proxy-node/main/setup.sh | bash -s -- <NEXT_PORT> 77.37.44.130
   ```

---

## 4. Validation & Health Check
1. **Gateway Check:** Run `ha-gateway status` on the device or check live logs with `ha-gateway logs`.
2. **Telegram Handshake:** Send `/start` to the newly created `@<devicename>_hermes_bot`.
3. **Proxy Check (if enabled):**
   ```bash
   curl --socks5 127.0.0.1:<PORT> https://ipinfo.io/json
   ```

---

## 5. Failure Recovery & Troubleshooting

| Symptom | Root Cause | Immediate Fix |
| :--- | :--- | :--- |
| `Failed to connect user scope bus` | Systemd/DBus missing in PRoot | Run `curl -sSL .../fix-gateway.sh \| bash` (switches to native `ha-gateway`). |
| Bot not replying to messages | User ID whitelist mismatch | Verify ID is `7361027380` or set `TELEGRAM_ALLOWED_USERS=*`. |
| Android killing background process | Battery optimization active | Run `termux-wake-lock` + set App Battery to "Unrestricted". |
| Port collision on proxy node | Allocated port already in use | Query `/opt/MyFiles/Projects/AnamikaPC/data/sms/authorized_proxy_keys.txt` for next available port (10801+). |

---

## 6. Continuous Improvement & Version Notes
- **v1.0.0 (2026-09-07):** Initial standardized release with Native Termux Daemon (`ha-gateway`), AES-128 credential store integration, and zero hardcoded git secrets.
