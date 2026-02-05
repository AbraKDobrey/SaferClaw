# Upload & Deploy OpenClaw (Native, No Docker)

## Prerequisites

- VPS with Ubuntu 22.04/24.04
- SSH access to your VPS user
- OpenClaw source code

## Stap 1: Upload deployment files

```bash
./upload-to-vps.exp upload
```

## Stap 2: Setup VPS (eenmalig)

SSH naar je VPS en run:

```bash
sudo bash ~/openclaw-deploy/vps-setup-native.sh
```

Dit installeert:
- Node.js 22 + pnpm
- Bun (voor build scripts)
- Nginx, certbot
- System tools (git, tmux, ffmpeg, ripgrep, etc.)
- Sudo NOPASSWD voor je user

## Stap 3: Upload OpenClaw source

```bash
./upload-to-vps.exp upload-source
```

Of handmatig:

```bash
scp -r -P YOUR_SSH_PORT -i ~/.ssh/vps_openclaw openclaw-source/* YOUR_USER@YOUR_VPS_IP:/opt/openclaw/
```

## Stap 4: Install & Build

```bash
./upload-to-vps.exp install
```

Of handmatig op de VPS:

```bash
bash ~/openclaw-deploy/install-openclaw.sh
```

## Stap 5: SSL certificaat

Op de VPS:

```bash
sudo bash ~/openclaw-deploy/setup-ssl.sh
```

## Stap 6: Telegram webhook

Op de VPS:

```bash
sudo bash ~/openclaw-deploy/setup-webhook.sh
```

## Dagelijks gebruik

```bash
# Status
sudo systemctl status openclaw

# Logs
journalctl -u openclaw -f

# Restart
sudo systemctl restart openclaw

# Update
bash ~/openclaw-deploy/update-openclaw.sh
```

## Migratie van Docker

Als je al een Docker deployment hebt draaien:

```bash
# 1. Stop Docker container
docker-compose -f /opt/openclaw/docker-compose.yml down
docker rm -f openclaw-gateway

# 2. Backup config from container (if needed)
# Config is at /home/YOUR_USER/.openclaw/ already

# 3. Install native
bash ~/openclaw-deploy/install-openclaw.sh

# 4. (Optional) Remove Docker
sudo apt-get remove -y docker.io docker-ce docker-ce-cli containerd.io
sudo apt-get autoremove -y
```
