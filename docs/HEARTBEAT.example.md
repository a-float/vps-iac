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

```markdown
- [ ] Workspace ID: `cat workspace/.nanobot/workspace-id`
- [ ] Session dir exists: `ls sessions/<workspace-id>/`
- [ ] Memory git status: `cd workspace && git status`
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

### 4. Monitor Gateway Health (Every Run)

**Schedule:** Every heartbeat.

**Check:** Gateway health endpoint

```bash
curl -sf http://127.0.0.1:18790/health | jq -r '.status'
```

**Alert if:** Not "ok" or WebSocket not "running".

---

### 5. Check for Nanobot Updates (Weekly)

**Schedule:** Runs every heartbeat; reports only on Sundays.

**Check:** Upstream nanobot version vs. deployed

```bash
# In vps-iac repo
cd /home/nanobot/.nanobot/workspace/vps-iac
git fetch origin main
git log --oneline -1 origin/main
git log --oneline -1 HEAD
```

**Alert if:** Commits behind origin/main.

---

## Paused Tasks (Ideas for Later)

### 6. Analyze Memory Growth

Track `memory/history.jsonl` size over time. Alert if growing unusually fast.

### 7. Check MCP Server Health

Ping configured MCP servers (GitHub, Knowledge Graph) for responsiveness.

### 8. Review Dream Consolidation

Check `/dream-log` output for unexpected memory changes.

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

---

## Task Format

Each task under `## Active Tasks` should be a markdown section with:

```markdown
### N. Task Name (Frequency)

**Schedule:** When it runs.

**Check:** What to verify (bash command or description).

**Alert if:** Condition that triggers notification.
```

The agent reads this file, executes the checks, and reports only actionable findings.