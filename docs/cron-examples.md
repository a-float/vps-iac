# Cron Examples for Nanobot Maintenance

These examples show how to schedule recurring tasks using nanobot's built-in cron tool (chat-based) or system cron (host-level).

---

## Nanobot Cron (Chat-Based)

Run from any nanobot chat (WebUI, Telegram, etc.):

```bash
# Daily backup reminder at 03:00 Warsaw time
/cron add "Run nanobot backup" --cron "0 3 * * *" --tz Europe/Warsaw

# Weekly GitHub MCP health check
/cron add "Check GitHub MCP" --cron "0 4 * * 0" --tz Europe/Warsaw

# Every 6 hours: verify workspace integrity
/cron add "Verify workspace" --every 21600

# One-time: remind me to review PRs tomorrow 10am
/cron add "Review PRs" --at "2025-01-15T10:00:00" --tz Europe/Warsaw
```

**List cron jobs:**
```
/cron list
```

**Remove a job:**
```
/cron remove <job-id>
```

**View history:**
```
/cron history <job-id>
```

> Nanobot cron jobs run as **scheduled turns in their origin chat** and always deliver results back to that chat.

---

## System Cron (Host-Level)

For infrastructure tasks (backups, disk checks, updates), use host cron.

### Edit crontab:
```bash
sudo crontab -e
```

### Examples:

```cron
# Daily backup at 03:00 (using tar method)
0 3 * * * /home/nanobot/.nanobot/workspace/vps-iac/scripts/backup-nanobot.sh tar >> /var/log/nanobot-backup.log 2>&1

# Daily restic backup at 03:30 (requires env vars in /etc/nanobot-backup.env)
30 3 * * * source /etc/nanobot-backup.env && /home/nanobot/.nanobot/workspace/vps-iac/scripts/backup-nanobot.sh restic >> /var/log/nanobot-backup.log 2>&1

# Weekly disk space check (alert if >80%)
0 6 * * 1 df -h /opt/nanobot | awk 'NR==2 {if ($5+0 > 80) print "WARNING: " $5 " used on /opt/nanobot"}' | mail -s "Nanobot Disk Alert" admin@example.com

# Monthly nanobot image update check (manual deploy via GitHub Actions)
0 9 1 * * cd /home/nanobot/.nanobot/workspace/vps-iac && git fetch origin main && git log --oneline -1 origin/main >> /var/log/nanobot-update-check.log 2>&1
```

### Environment File for Restic (`/etc/nanobot-backup.env`):
```bash
# chmod 600 /etc/nanobot-backup.env
export RESTIC_REPOSITORY="s3:s3.amazonaws.com/your-bucket/nanobot-backup"
export RESTIC_PASSWORD="your-restic-password"
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

---

## Systemd Timer (Alternative to Cron)

More robust than cron — handles missed runs, logging, dependencies.

### `/etc/systemd/system/nanobot-backup.service`:
```ini
[Unit]
Description=Nanobot Backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
EnvironmentFile=/etc/nanobot-backup.env
ExecStart=/home/nanobot/.nanobot/workspace/vps-iac/scripts/backup-nanobot.sh restic
StandardOutput=journal
StandardError=journal
```

### `/etc/systemd/system/nanobot-backup.timer`:
```ini
[Unit]
Description=Daily Nanobot Backup

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
```

### Enable:
```bash
systemctl daemon-reload
systemctl enable --now nanobot-backup.timer
systemctl list-timers nanobot-backup.timer
```

---

## GitHub Actions (For Image Updates)

Your existing `.github/workflows/build-and-publish.yml` builds and publishes Docker images.

### Manual Deploy Workflow Dispatch:
```bash
# Trigger via gh CLI
gh workflow run build-and-publish.yml -f deploy=true -r main

# Or via GitHub UI: Actions → Build and Publish → Run workflow
```

### Auto-Deploy on Main Branch Push:
The workflow already triggers on `push: branches: [main]`. After image is published, update your VPS:

```bash
# On VPS (manual or via cron)
cd /opt/nanobot
docker compose pull
docker compose up -d
```

---

## Heartbeat vs Cron vs Systemd

| Feature | Heartbeat | Nanobot Cron | System Cron | Systemd Timer |
|---------|-----------|--------------|-------------|---------------|
| **Runs in** | Gateway process | Gateway process | Host OS | Host OS |
| **Delivers to** | Most recent chat | Origin chat | Stdout/log/email | Journal |
| **Suppresses "OK"** | Yes | No | No | No |
| **Precision** | ~30 min interval | Cron/interval/at | Cron | Calendar |
| **Survives restart** | Yes (HEARTBEAT.md) | Yes (workspace/cron/) | Yes | Yes |
| **Best for** | Background monitoring | User reminders, agent tasks | Backups, sysadmin | Critical infra tasks |

---

## Recommended Setup for Your VPS

| Task | Mechanism | Schedule |
|------|-----------|----------|
| Nanobot data backup | Systemd timer + restic | Daily 03:30 |
| Disk space check | System cron | Weekly Mon 06:00 |
| Workspace integrity | Nanobot heartbeat | Every 30 min |
| GitHub MCP health | Nanobot cron | Weekly Sun 04:00 |
| Image update check | GitHub Actions + manual | On demand |
| Dream consolidation | Built-in (config) | Every 12 hours |

---

## Quick Commands

```bash
# Test backup script
/home/nanobot/.nanobot/workspace/vps-iac/scripts/backup-nanobot.sh tar

# View backup logs
tail -f /var/log/nanobot-backup.log

# List systemd timers
systemctl list-timers --all | grep nanobot

# List nanobot cron jobs (from chat)
/cron list
```