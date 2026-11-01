# HEARTBEAT.md — Example Background Tasks

This file demonstrates how to use nanobot's protected heartbeat system for recurring background checks. The heartbeat job runs every 30 minutes (configurable via `gateway.heartbeat.intervalS`) and executes tasks listed under `## Active Tasks`.

**Only actionable results are delivered** to the most recent chat — routine "nothing changed" results are suppressed.

---

## Active Tasks

### 1. Verify Workspace Integrity (Daily)

**Schedule:** Runs every heartbeat; reports only on issues.

**Check:**
- Workspace ID matches session directory
- Memory files are readable
- Git repo in `memory/.git` is healthy

```bash
cat workspace/.nanobot/workspace-id
ls sessions/<workspace-id>/
cd workspace && git status
```

**Alert if:** Workspace ID mismatch, missing session dir, git corruption.

---

### 2. Check Disk Space (Every Run)

**Schedule:** Every heartbeat (30 min).

**Check:** Disk usage on `/opt/nanobot`

```bash
df -h /opt/nanobot | awk 'NR==2 {print $5 " used (" $3 " / " $2 ")"}'
```

**Alert if:** > 80% used.

---

### 3. Verify Backup Recency (Daily)

**Schedule:** Runs every heartbeat; reports only if backup is stale.

**Check:** Latest restic snapshot age

```bash
restic snapshots --repo $RESTIC_REPO --latest 1 --json | jq -r '.[0].time'
```

**Alert if:** Last backup > 28 hours old.

---

## How to Use

1. **Copy this file** to your agent workspace:
   ```bash
   cp docs/HEARTBEAT.example.md /opt/nanobot/.nanobot/workspace/HEARTBEAT.md
   ```

2. **Ensure heartbeat is enabled** in `config.json`:
   ```json
   {
     "gateway": {
       "heartbeat": {
         "enabled": true,
         "intervalS": 1800,
         "keepRecentMessages": 8
       }
     }
   }
   ```

3. **Restart gateway** (or wait for next interval):
   ```bash
   docker compose -f /opt/nanobot/compose.yml restart nanobot-gateway
   ```

4. **Results appear** in your most recent chat (Telegram, WebUI, etc.) only when a check finds something actionable.

---

## Customizing Schedule

The heartbeat runs on a fixed interval (`intervalS`). For precise cron-like scheduling (e.g., "daily at 03:00"), use the **cron tool** instead:

```
/cron add "Check backup" --cron "0 3 * * *" --tz Europe/Warsaw
```

Cron jobs run as scheduled turns in their origin chat and **always deliver results** (unlike heartbeat which suppresses "nothing to report").
