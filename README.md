# ⚡ Termux Hermes Agent Installer (Android)

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_Termux-10B981?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Hermes_Agent-Nous_Research-8B5CF6?style=for-the-badge&logo=openai&logoColor=white" />
  <img src="https://img.shields.io/badge/Architecture-ARM64_%26_ARMv7-3B82F6?style=for-the-badge&logo=arm&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-Tested_%26_Automated-F59E0B?style=for-the-badge&logo=statuspage&logoColor=white" />
</p>

An automated, bulletproof **1-Line Installer** for running **Hermes Agent** (by Nous Research) natively on Android via Termux.

---

## 🚀 1-Line Quick Install

Open **Termux** on your Android device, paste and run:

```bash
curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash
```

---

## ⚡ Optional: Install & Pre-configure API Key in 1 Step

You can pass your API Key directly during installation:

```bash
# For OpenRouter:
curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash -s -- --api-key "sk-or-v1-..." --provider openrouter

# For Google Gemini:
curl -sSL https://raw.githubusercontent.com/arificialanamika/termux-hermes-agent/main/install.sh | bash -s -- --api-key "AIzaSy..." --provider google
```

---

## 🛠️ What This Script Automates

1. ⚙️ **Native Android C/Rust/Python Toolchain:** Installs `clang`, `rust`, `make`, `python3`, `pkg-config`, `libffi`, `openssl`, `nodejs-lts`, and `ripgrep`.
2. 🔋 **CPU WakeLock:** Acquires Termux WakeLock to prevent Android OS from sleeping during installation.
3. 📦 **Hermes Core Installation:** Pulls and builds Hermes Agent virtual environment with all required Android C-extensions.
4. ⚡ **Shell Aliases & PATH Linking:** Adds quick shortcuts (`ha`, `ha-chat`, `ha-doctor`, `ha-model`) to your shell.

---

## 🎯 How to Use Hermes on Android

Once installed, use any of these commands in Termux:

| Command | Action |
| :--- | :--- |
| `hermes` (or `ha`) | Launch full interactive chat session |
| `hermes chat -q "Your prompt"` | Quick one-shot query |
| `hermes setup` | Launch configuration & provider wizard |
| `hermes model` | Change LLM model or provider |
| `hermes doctor` | Check environment and tool health |
| `hermes gateway` | Run multi-platform bot gateway (Discord/Telegram/WhatsApp) |

---

## 📱 Prerequisites (Android)

* **Termux from F-Droid** (Recommended: Do NOT use Google Play Store version as it is outdated).
* In Android Settings, set Termux Battery usage to **Unrestricted**.

---

## 📜 License
MIT License • Created with ❤️ by **Anamika & Anant**
