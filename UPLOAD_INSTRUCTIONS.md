# Upload & Deploy OpenClaw (Native, No Docker)

## Prerequisites

- VPS with Ubuntu 22.04/24.04
- SSH access to your VPS user

> **Note**: OpenClaw source code is bundled in `openclaw-source/`. No separate download needed.

## Step 1: Upload deployment files + source

```bash
./upload-to-vps.exp upload
```

This uploads the deployment scripts and config to `~/saferclaw/` on the VPS.

Then upload the bundled source:

```bash
./upload-to-vps.exp upload-source
```

This copies `openclaw-source/` to `/opt/openclaw/` on the VPS.

## Step 2: Setup VPS (one-time)

SSH into your VPS and run:

```bash
sudo bash ~/saferclaw/vps-setup-native.sh
```

This installs:
- Node.js 22 + pnpm
- Bun (for build scripts)
- Nginx, certbot
- System tools (git, tmux, ffmpeg, ripgrep, etc.)
- Sudo NOPASSWD for your user

## Step 3: Install & Build

```bash
./upload-to-vps.exp install
```

Or manually on the VPS:

```bash
bash ~/saferclaw/install-openclaw.sh
```

> The install script automatically copies the bundled source to `/opt/openclaw/` if it's not already there.

## Step 4: SSL Certificate

On the VPS:

```bash
sudo bash ~/saferclaw/setup-ssl.sh
```

## Step 5: Telegram Webhook

On the VPS:

```bash
bash ~/saferclaw/setup-webhook.sh
```

## Daily Usage

```bash
# Status
sudo systemctl status openclaw

# Logs
journalctl -u openclaw -f

# Restart
sudo systemctl restart openclaw

# Update
bash ~/saferclaw/update-openclaw.sh
```

## Migration from Docker

If you already have a Docker deployment running:

```bash
# 1. Stop Docker container
docker-compose -f /opt/openclaw/docker-compose.yml down
docker rm -f openclaw-gateway

# 2. Backup config from container (if needed)
# Config is at /home/YOUR_USER/.openclaw/ already

# 3. Install native
bash ~/saferclaw/install-openclaw.sh

# 4. (Optional) Remove Docker
sudo apt-get remove -y docker.io docker-ce docker-ce-cli containerd.io
sudo apt-get autoremove -y
```
