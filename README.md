# ⚡ Termux Hermes Agent OS & Bot Gateway (Android)

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_Termux-10B981?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Hermes_Agent-Nous_Research-8B5CF6?style=for-the-badge&logo=openai&logoColor=white" />
  <img src="https://img.shields.io/badge/Engine-PRoot_Ubuntu_ARM64-3B82F6?style=for-the-badge&logo=ubuntu&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-Ultra_Fast_2_Min_Install-F59E0B?style=for-the-badge&logo=statuspage&logoColor=white" />
</p>

An automated, high-speed **1-Line Installer & Bot Gateway Connector** for running **Hermes Agent** natively on Android (Termux) with zero wheel compilation errors and 1-click Telegram / Discord bot connection.

---

## 🚀 1. Install Hermes Agent (2 Minutes)

Open **Termux** on your phone, paste and run:

```bash
curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash
```

---

## 🤖 2. Connect Hermes to Telegram Bot (1-Click)

To communicate with your phone's Hermes Agent from **Telegram** (voice notes, text, anywhere on the go):

1. Open Telegram, message `@BotFather`, send `/newbot`, and copy your `BOT_TOKEN`.
2. Run this single command in Termux:

```bash
curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- telegram <YOUR_TELEGRAM_BOT_TOKEN>
```

*Hermes Gateway will start in the background, and you can start chatting directly in Telegram!*

---

## 🎮 3. Connect Hermes to Discord Bot (1-Click)

To connect your Hermes Agent to **Discord**:

```bash
curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/setup-gateway.sh | bash -s -- discord <YOUR_DISCORD_BOT_TOKEN>
```

---

## 🎯 Direct CLI Commands (Inside Termux)

| Command | Action |
| :--- | :--- |
| `hermes` (or `ha`) | Launch full interactive CLI chat session |
| `hermes chat -q "query"` | Quick one-shot answer |
| `hermes setup` | Setup wizard (Model / Provider / Keys) |
| `hermes model` | Change LLM model or provider |
| `hermes doctor` | Environment diagnostics & healthcheck |

---

## 📜 License
MIT License • Created with ❤️ by **Anamika & Anant**
