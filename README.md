<p align="center">
  <img src="saferclaw-banner.png" alt="SaferClaw" width="100%">
</p>

# SaferClaw

**A security-hardened deployment kit for [OpenClaw](https://github.com/openclaw/openclaw) -- the open-source autonomous AI agent.**

SaferClaw takes the powerful OpenClaw platform and wraps it in a locked-down, production-ready configuration that addresses every critical vulnerability found during a 7-phase security audit. The result: you get an autonomous AI assistant on Telegram that can write code, browse the web, manage files, and run scheduled tasks -- without giving it the keys to nuke your server.

---

## Table of Contents

- [What is OpenClaw?](#what-is-openclaw)
- [OpenClaw vs SaferClaw](#openclaw-vs-saferclaw)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Step 1: Get a VPS](#step-1-get-a-vps)
- [Step 2: Harden the VPS](#step-2-harden-the-vps)
- [Step 3: Get Your API Keys](#step-3-get-your-api-keys)
- [Step 4: Get a Domain (Free)](#step-4-get-a-domain-free)
- [Step 5: Install SaferClaw on the VPS](#step-5-install-saferclaw-on-the-vps)
- [Step 6: Configure Everything](#step-6-configure-everything)
- [Step 7: SSL & Telegram Webhook](#step-7-ssl--telegram-webhook)
- [Step 8: Start & Verify](#step-8-start--verify)
- [Daily Usage](#daily-usage)
- [Updating](#updating)
- [Model Recommendations](#model-recommendations)
- [Recommended Coding Workflow](#recommended-coding-workflow)
- [Security Details](#security-details)
- [File Reference](#file-reference)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## What is OpenClaw?

[OpenClaw](https://github.com/openclaw/openclaw) is an open-source personal AI assistant platform (167k+ stars) that turns LLMs into autonomous agents. It supports:

- **Multi-provider AI**: Claude, GPT-4, Grok, Gemini, Ollama, and 15+ providers
- **Telegram/WhatsApp/Discord**: Chat with your AI agent from anywhere
- **Tool use**: Shell execution, file editing, web search, web fetch, git operations
- **Skills framework**: 50+ plugins for coding, summarization, email, and more
- **Memory**: Persistent conversation storage and retrieval
- **Sandboxed execution**: Configurable isolation for code the AI writes
- **Cron jobs**: Scheduled autonomous tasks (daily briefings, health checks)
- **Sub-agents**: Spawn child agents for parallel work

It is, essentially, your own personal AI that lives on a server and is available 24/7 via Telegram.

---

## OpenClaw vs SaferClaw

OpenClaw out of the box ships with **permissive defaults** designed for local development. Running it on a VPS without hardening is dangerous. Here's what SaferClaw changes:

| Area | OpenClaw (Default) | SaferClaw |
|------|-------------------|-----------|
| **Elevated mode** | Available (`full` bypasses ALL security) | **Disabled entirely** |
| **Auto-allow skills** | Skills can auto-approve their own binaries | **Disabled** -- dangerous skills removed from config |
| **Sandbox** | Optional, often `off` | **Off** (native deployment, no Docker); security via systemd hardening + elevated mode disabled |
| **Gateway binding** | `0.0.0.0` (open to internet) | **`loopback`** (localhost only, behind Nginx) |
| **Gateway auth** | Optional | **Token-based** (random 64-char hex) |
| **Control UI** | Enabled (web dashboard) | **Disabled** (attack surface reduction) |
| **mDNS/Bonjour** | Enabled (broadcasts presence on LAN) | **Disabled** (`OPENCLAW_DISABLE_BONJOUR=1`) |
| **Telegram DMs** | `open` (anyone can message) | **`allowlist`** (only your user ID) |
| **Group chats** | Enabled | **Disabled** |
| **HTTP API endpoints** | Enabled (chatCompletions, responses) | **Disabled** |
| **Remote nodes** | Allowed | **Denied** (no remote command dispatch) |
| **Tailscale** | Available | **Disabled** |
| **Dangerous skills** | `skill-creator`, `clawhub`, `mcporter` enabled | **Disabled** |
| **Tool deny list** | Empty | **`gateway`, `nodes`** denied |
| **DM scope** | `main` (shared context = cross-user leakage) | **`per-channel-peer`** (isolated) |
| **Workspace access** | `rw` on host filesystem | **`rw` scoped to `/workspace` only** |
| **Sensitive data in logs** | Full content | **Redacted** (`redactSensitive: "tools"`) |
| **Browser automation** | Enabled (Puppeteer) | **Disabled** |
| **Plugins** | Enabled | **Enabled** (only Telegram plugin active; dangerous plugins disabled) |
| **Systemd hardening** | None | **`PrivateTmp`, `ProtectHome`, `NoNewPrivileges`** |
| **Process limits** | Unlimited | **Timeouts enforced** (600s exec, 1800s agent) |
| **Deployment** | Docker or native | **Native only** (systemd, no container overhead) |

### What SaferClaw Keeps Enabled

SaferClaw is **not** about crippling OpenClaw. These powerful features remain fully functional:

- Shell execution (security via systemd hardening, elevated mode disabled, scoped workspace, and process timeouts)
- Full coding agent capabilities (via Cursor CLI, Claude Code, or OpenCode)
- Web search and web fetch
- GitHub integration
- Telegram messaging with streaming responses
- Memory and conversation persistence
- Cron jobs (daily briefings, scheduled tasks)
- Sub-agents for parallel work
- tmux for terminal session management
- File read/write/edit inside the scoped workspace
- Whisper for voice message transcription

---

## Architecture Overview

```
┌─────────────┐     HTTPS (443)     ┌──────────┐     localhost:47832     ┌──────────────┐
│  Telegram   │ ──────────────────> │  Nginx   │ ──────────────────────> │  OpenClaw    │
│  (You)      │ <────────────────── │  + SSL   │ <────────────────────── │  Gateway     │
└─────────────┘                     └──────────┘                         └──────┬───────┘
                                                                                │
                                                                   ┌────────────┼────────────┐
                                                                   │            │            │
                                                              ┌────▼────┐ ┌─────▼─────┐ ┌───▼────┐
                                                              │ Sandbox │ │ OpenRouter│ │ Memory │
                                                              │ (exec)  │ │ (Grok 4.1)│ │ SQLite │
                                                              │         │ │           │ │        │
                                                              └─────────┘ └───────────┘ └────────┘
```

- **You** message the bot on Telegram
- **Nginx** terminates SSL and proxies webhooks to the gateway
- **OpenClaw Gateway** runs natively via systemd (no Docker), processes messages, calls the AI model, runs tools
- **Sandbox** isolates exec calls with scoped workspace, timeouts, and process limits
- **OpenRouter** routes to your chosen AI model (Grok 4.1 Fast recommended)
- **Memory** persists conversations locally in SQLite (no external embedding services)

> **Note**: This is a fully native deployment. OpenClaw runs directly on the host via systemd -- no Docker required. Security comes from systemd hardening, a dedicated user, Nginx reverse proxy, config-level sandbox enforcement, and restrictive tool/skill policies.

---

## Prerequisites

- A Linux VPS (Ubuntu 22.04 or 24.04 recommended) -- see [Step 1](#step-1-get-a-vps)
- A Telegram account
- At least one AI provider API key (OpenRouter recommended)
- A computer with SSH access to configure things
- ~30 minutes of setup time

---

## Step 1: Get a VPS

You need a Virtual Private Server to run SaferClaw 24/7. Here are good options:

| Provider | Cheapest Plan | RAM | Notes |
|----------|--------------|-----|-------|
| [Hetzner](https://www.hetzner.com/cloud) | ~€4/mo | 2GB | Best value, EU & US datacenters |
| [Contabo](https://contabo.com/en/vps/) | ~€6/mo | 4GB | Great specs for the price |
| [DigitalOcean](https://www.digitalocean.com/) | $6/mo | 1GB | Beginner-friendly |
| [Vultr](https://www.vultr.com/) | $6/mo | 1GB | Many locations |
| [Oracle Cloud](https://www.oracle.com/cloud/free/) | Free | 1GB | Always-free tier (ARM) |

**Recommended specs:**
- **OS**: Ubuntu 22.04 or 24.04 LTS
- **RAM**: 2GB minimum (4GB recommended for heavier workloads)
- **CPU**: 1-2 vCPUs
- **Storage**: 20GB+
- **Network**: Public IPv4

### After purchasing:

1. Note your VPS **IP address**
2. Note your **root password** or SSH key
3. Create a non-root user:

```bash
# SSH in as root
ssh root@YOUR_VPS_IP

# Create a user
adduser openclaw

# Add to sudo group
usermod -aG sudo openclaw

# Switch to the new user and set up SSH key
su - openclaw
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

4. Set up SSH key authentication (recommended):

```bash
# On YOUR LOCAL machine, generate a key:
ssh-keygen -t ed25519 -f ~/.ssh/vps_openclaw -C "openclaw-vps"

# Copy it to the VPS:
ssh-copy-id -i ~/.ssh/vps_openclaw.pub openclaw@YOUR_VPS_IP

# Add to your ~/.ssh/config for easy access:
cat >> ~/.ssh/config << 'EOF'
Host openclaw-vps
    HostName YOUR_VPS_IP
    User openclaw
    Port 22
    IdentityFile ~/.ssh/vps_openclaw
EOF

# Test:
ssh openclaw-vps
```

---

## Step 2: Harden the VPS

Before installing anything, lock down your VPS.

### 2.1 Change SSH Port (optional but recommended)

```bash
sudo nano /etc/ssh/sshd_config

# Change:
#   Port 22
# To:
#   Port 2222    (or any high port you like)

sudo systemctl restart sshd
```

### 2.2 Disable Root Login & Password Auth

```bash
sudo nano /etc/ssh/sshd_config

# Set these:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes

sudo systemctl restart sshd
```

### 2.3 Set Up Firewall (UFW)

```bash
sudo apt update && sudo apt install -y ufw

# Allow your SSH port
sudo ufw allow 2222/tcp comment 'SSH'

# Allow HTTP/HTTPS for the bot
sudo ufw allow 80/tcp comment 'HTTP (certbot)'
sudo ufw allow 443/tcp comment 'HTTPS (Telegram webhook)'

# Enable
sudo ufw enable
sudo ufw status
```

### 2.4 Install Fail2ban

```bash
sudo apt install -y fail2ban

# Create config
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = 2222
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 2.5 Enable Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## Step 3: Get Your API Keys

You need keys for several services. Here's where to get each one:

### 3.1 Telegram Bot Token (Required)

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Give it a name and username
4. Copy the **bot token** (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. Message [@userinfobot](https://t.me/userinfobot) to get your **Telegram user ID** (a number like `123456789`)

### 3.2 OpenRouter API Key (Recommended AI Provider)

1. Go to [openrouter.ai](https://openrouter.ai)
2. Sign up / log in
3. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
4. Create a new API key
5. Add credit ($5-10 to start)

**Why OpenRouter?** It gives you access to 200+ models through a single API key. You can switch models in the config without getting new keys. And Grok 4.1 Fast through OpenRouter is extremely cost-effective.

### 3.3 GitHub Token (Optional, for git operations)

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Create a **classic** token with scopes: `repo`, `read:user`
3. Copy the token

### 3.4 Anthropic / OpenAI Keys (Optional, for fallback)

- **Anthropic**: [console.anthropic.com](https://console.anthropic.com) -> API Keys
- **OpenAI**: [platform.openai.com/api-keys](https://platform.openai.com/api-keys)

These are optional if you're using OpenRouter as your primary provider.

### 3.5 Cursor CLI Key (Optional, for advanced coding)

If you want the agent to use Cursor CLI as its coding tool:
1. Go to [cursor.com](https://cursor.com) -> Account Settings
2. Copy your API key

---

## Step 4: Get a Domain (Free)

Telegram webhooks require HTTPS, which requires a domain name. DuckDNS gives you one for free.

1. Go to [duckdns.org](https://www.duckdns.org)
2. Log in with GitHub or Google
3. Create a subdomain (e.g., `myopenclaw` -> `myopenclaw.duckdns.org`)
4. Copy your **DuckDNS token**
5. Point it to your VPS IP (this is done automatically by the setup script)

---

## Step 5: Install SaferClaw on the VPS

### 5.1 Clone SaferClaw

```bash
ssh openclaw-vps

# Clone this repo (includes OpenClaw source code)
git clone https://github.com/AbraKDobrey/SaferClaw.git ~/saferclaw
cd ~/saferclaw
```

> **Note**: This repo bundles the OpenClaw source code in `openclaw-source/`. You do NOT need to clone the upstream OpenClaw repo separately. The install script handles copying the source automatically.

### 5.2 Run VPS Setup

Edit the variables at the top of `vps-setup-native.sh`:

```bash
nano vps-setup-native.sh

# Fill in:
#   DOMAIN="myopenclaw.duckdns.org"
#   DUCKDNS_TOKEN="your-duckdns-token"
#   DUCKDNS_SUBDOMAIN="myopenclaw"
#   OPENCLAW_USER="openclaw"
```

Then run it:

```bash
sudo bash vps-setup-native.sh
```

This installs:
- Node.js 22 LTS + pnpm (via corepack)
- Bun (for build scripts)
- Nginx + Certbot (for SSL)
- GitHub CLI
- AI coding CLIs: Cursor CLI, OpenAI Codex, Claude Code (for coding skills)
- System tools (git, tmux, ffmpeg, ripgrep, jq, python3)
- Firewall rules
- DuckDNS auto-updater (cron every 5 min)

---

## Step 6: Configure Everything

### 6.1 Create Environment File

```bash
cp ~/saferclaw/.env.template /opt/openclaw/.env.openclaw
chmod 600 /opt/openclaw/.env.openclaw
nano /opt/openclaw/.env.openclaw
```

Fill in all values:

```bash
# Generate random tokens:
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
TELEGRAM_WEBHOOK_SECRET=$(openssl rand -hex 16)
HOOKS_TOKEN=$(openssl rand -hex 16)

# Your API keys:
TELEGRAM_BOT_TOKEN=your-bot-token-from-botfather
OPENROUTER_API_KEY=sk-or-v1-your-openrouter-key
GH_TOKEN=ghp_your-github-token

# Optional:
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-proj-...
CURSOR_API_KEY=key_...
```

### 6.2 Create Config File

```bash
cp ~/saferclaw/config.json5 ~/.openclaw/config.json5
nano ~/.openclaw/config.json5
```

**You MUST change these values:**

1. Replace the `0` in `allowFrom` with your actual Telegram user ID (find it via @userinfobot)
2. If you have a domain and SSL set up, uncomment the `webhookUrl` and `webhookPath` lines and replace `YOUR_DOMAIN`. Otherwise, leave them commented out -- the bot will use long-polling.

> **Important**: The `plugins.enabled` and `plugins.entries.telegram.enabled` fields MUST be `true` for Telegram to work. They are already set correctly in the default config.

### 6.3 Install & Build

```bash
bash ~/saferclaw/install-openclaw.sh
```

This handles:
- Copying the bundled source to `/opt/openclaw/` (if not already present)
- `pnpm install` for dependencies
- Building the application
- Copying config files
- Installing the systemd service
- Starting OpenClaw

---

## Step 7: SSL & Telegram Webhook

### 7.1 Get SSL Certificate

Edit and run the SSL setup script:

```bash
nano ~/saferclaw/setup-ssl.sh
# Fill in DOMAIN and EMAIL

sudo bash ~/saferclaw/setup-ssl.sh
```

### 7.2 Set Telegram Webhook

Edit and run the webhook setup script:

```bash
nano ~/saferclaw/setup-webhook.sh
# Fill in DOMAIN, BOT_TOKEN, and WEBHOOK_SECRET
# (WEBHOOK_SECRET must match the one in your .env.openclaw)

bash ~/saferclaw/setup-webhook.sh
```

---

## Step 8: Start & Verify

```bash
# Start the service
sudo systemctl start openclaw

# Check status
sudo systemctl status openclaw

# Watch logs
journalctl -u openclaw -f
```

Now open Telegram and send a message to your bot. If everything is working, it should respond.

---

## Daily Usage

```bash
# Check status
sudo systemctl status openclaw

# View live logs
journalctl -u openclaw -f

# Restart
sudo systemctl restart openclaw

# Stop
sudo systemctl stop openclaw
```

---

## Updating

SaferClaw includes an update script with **automatic rollback** if the update fails:

```bash
bash ~/saferclaw/update-openclaw.sh
```

To get the latest source, first update your SaferClaw clone:

```bash
cd ~/saferclaw && git pull
```

Then run the update script:

```bash
bash ~/saferclaw/update-openclaw.sh
```

This will:
1. Backup your current config and dist
2. Stop OpenClaw
3. Sync the latest bundled source to `/opt/openclaw/`
4. Rebuild
5. Restart
6. Run health check
7. **Automatically rollback** if health check fails

---

## Model Recommendations

### Primary: Grok 4.1 Fast via OpenRouter

For the best price/performance ratio, use **Grok 4.1 Fast** through OpenRouter:

```json5
// In config.json5 -> agents.defaults.model
model: { primary: "openrouter/x-ai/grok-4.1-fast" }
```

**Why this model?**
- Excellent coding ability (comparable to Claude Sonnet)
- Very fast response times
- Significantly cheaper than Claude/GPT-4 for autonomous agent workloads
- Great at following system prompts and tool-use patterns
- Available 24/7 with high rate limits via OpenRouter

### Alternatives

| Model | Config Value | Use Case |
|-------|-------------|----------|
| Grok 4.1 Fast | `openrouter/x-ai/grok-4.1-fast` | Best all-around (recommended) |
| Claude 4 Sonnet | `openrouter/anthropic/claude-sonnet-4` | Best for complex reasoning |
| GPT-4.1 Mini | `openrouter/openai/gpt-4.1-mini` | Budget option |
| Gemini 2.5 Flash | `openrouter/google/gemini-2.5-flash-preview` | Fast + cheap |

---

## Recommended Coding Workflow

SaferClaw's agent can write code, but for heavy development work you'll want a dedicated **CLI-based agentic coder** running on the VPS. The config is already set up to support these:

### Option 1: Claude Code (Recommended)

```bash
# The agent can invoke Claude Code on the VPS:
claude-code "Build a REST API with Express and PostgreSQL"
```

Free during the current beta. Excellent at multi-file refactoring.

### Option 2: OpenCode

[OpenCode](https://github.com/opencode-ai/opencode) -- open-source CLI coding agent.

```bash
# Install on the VPS
go install github.com/opencode-ai/opencode@latest

# Use
opencode "Add authentication middleware"
```

### Option 3: Cursor CLI

If you have a Cursor subscription:

```bash
cursor-cli agent "Refactor the database layer to use connection pooling"
```

Set `CURSOR_API_KEY` in your `.env.openclaw` to enable this.

### The Workflow

1. **You** message the Telegram bot with a high-level task
2. **The bot** (Grok 4.1 Fast) plans the approach and spawns a coding sub-agent
3. **The sub-agent** runs a CLI coder (Claude Code / OpenCode / Cursor) on the VPS
4. **The CLI coder** writes and tests the code
5. **The bot** reports results back to you on Telegram
6. **You** review, approve, and the bot commits + pushes to GitHub

This keeps the expensive coding LLM calls inside a specialized tool while the orchestration uses the cheaper Grok 4.1 Fast.

---

## Security Details

SaferClaw was built after a **7-phase security audit** of the OpenClaw codebase. Here's a summary of the critical vulnerabilities found and how SaferClaw addresses them:

### Critical Vulnerabilities Patched

| # | Vulnerability | Severity | SaferClaw Mitigation |
|---|--------------|----------|---------------------|
| 1 | **Auto-allow skills bypass** -- skills can auto-approve arbitrary binaries via `requires.bins` | CRITICAL | Dangerous skills (`skill-creator`, `clawhub`, `mcporter`) disabled in config |
| 2 | **Elevated mode bypass** -- `elevated=full` disables ALL security checks and approval prompts | CRITICAL | `elevated.enabled: false` -- entire feature disabled |
| 3 | **Skill script execution** -- skills can contain unvalidated executable scripts | HIGH | Dangerous skills (`skill-creator`, `clawhub`, `mcporter`) disabled |
| 4 | **Workspace skill override** -- workspace skills can replace bundled skills | HIGH | Workspace skill loading restricted; skill allowlist enforced |
| 5 | **Sandbox bypass via host parameter** -- elevated mode forces host execution | HIGH | Elevated mode disabled; native deployment uses systemd hardening instead of Docker sandbox |
| 6 | **DM scope cross-user leakage** -- default `dmScope: "main"` shares context | HIGH | Changed to `per-channel-peer` for full isolation |
| 7 | **mDNS information disclosure** -- broadcasts presence on LAN | MEDIUM | `OPENCLAW_DISABLE_BONJOUR=1` |
| 8 | **Environment variable injection** -- sandbox doesn't validate env vars | MEDIUM | Minimal env vars exposed; sensitive vars loaded only via `.env.openclaw` |

### Defense in Depth

SaferClaw applies security at multiple layers:

1. **Network**: Gateway bound to localhost; Nginx reverse proxy with TLS 1.2+; UFW firewall
2. **Authentication**: Token-based gateway auth; Telegram allowlist (user ID only)
3. **Isolation**: Native deployment (no Docker sandbox); elevated mode disabled; scoped workspace; process timeouts
4. **Least Privilege**: Systemd hardening (`PrivateTmp`, `ProtectHome`, `NoNewPrivileges`); dedicated user
5. **Logging**: All tool calls logged with sensitive data redacted; log rotation
6. **Monitoring**: Health check endpoint; systemd auto-restart on failure

---

## File Reference

| File | Purpose |
|------|---------|
| `openclaw-source/` | Bundled OpenClaw source code (security-audited) |
| `config.json5` | Main SaferClaw configuration (hardened settings) |
| `.env.template` | Template for environment variables / secrets |
| `vps-setup-native.sh` | One-time VPS setup (Node.js, Nginx, tools) |
| `install-openclaw.sh` | Build and install OpenClaw from source |
| `update-openclaw.sh` | Safe update with automatic rollback |
| `startup-cleanup.sh` | Pre-start orphan process cleanup |
| `setup-duckdns.sh` | Free dynamic DNS setup |
| `setup-ssl.sh` | SSL certificate via Let's Encrypt |
| `setup-webhook.sh` | Telegram webhook configuration |
| `nginx-openclaw.conf` | Nginx reverse proxy config (HTTPS, WebSocket) |
| `openclaw.service` | Systemd service unit (with hardening) |
| `upload-to-vps.exp` | Automated upload script (expect-based) |

---

## Troubleshooting

### Bot doesn't respond to Telegram messages

```bash
# Check if OpenClaw is running
sudo systemctl status openclaw

# Check logs for errors
journalctl -u openclaw -n 50

# Verify webhook is set
curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getWebhookInfo" | jq .

# Test OpenClaw is responding (check if gateway port is open)
ss -tlnp | grep 47832
```

### "Permission denied" errors

```bash
# Check file ownership
ls -la /opt/openclaw/
ls -la ~/.openclaw/

# Fix if needed
sudo chown -R $(whoami):$(whoami) /opt/openclaw
sudo chown -R $(whoami):$(whoami) ~/.openclaw
```

### Health check fails after update

The update script automatically rolls back. Check the backup:

```bash
ls /opt/openclaw/backups/
```

### SSL certificate renewal

Let's Encrypt certs auto-renew via certbot's cron/timer. Verify:

```bash
sudo certbot renew --dry-run
```

### High memory usage

OpenClaw runs natively, so standard Linux tools apply:

```bash
# Check what's using memory
ps aux --sort=-%mem | head -10

# Restart to clear accumulated memory
sudo systemctl restart openclaw

# Reduce concurrent agents in config.json5:
#   agents.defaults.maxConcurrent: 1    (down from 3)
#   agents.defaults.subagents.maxConcurrent: 2  (down from 5)
```

---

## License

SaferClaw deployment scripts and configuration are released under the [MIT License](https://opensource.org/licenses/MIT).

OpenClaw itself is licensed under its own MIT license -- see the [OpenClaw repository](https://github.com/openclaw/openclaw) for details.

---

## Credits

- [OpenClaw](https://github.com/openclaw/openclaw) -- the incredible open-source AI agent platform this project hardens
- Built with security insights from a 7-phase audit covering skills, exec, gateway, config, secrets, AI security, and operational security
