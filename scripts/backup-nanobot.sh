#!/bin/bash
# Nanobot Backup Script
# Usage: backup-nanobot.sh [restic|rsync|borg|tar]
# Default: tar (local compressed archive)

set -euo pipefail

NANOBOT_DIR="/opt/nanobot/.nanobot"
BACKUP_DIR="/var/backups/nanobot"
METHOD="${1:-tar}"
DATE="$(date +%Y-%m-%d_%H-%M-%S)"
HOSTNAME="$(hostname)"

# Exclude patterns (ephemeral/reproducible data)
EXCLUDES=(
    "--exclude=run/"
    "--exclude=updates/"
    "--exclude=cache/"
    "--exclude=logs/"
    "--exclude=cli-apps/"
    "--exclude=*.lock"
    "--exclude=*.sqlite3*"
    "--exclude=tool-results/"
)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

case "$METHOD" in
    tar)
        log "Creating tar.gz backup..."
        tar -czf "$BACKUP_DIR/nanobot-$HOSTNAME-$DATE.tar.gz" \
            -C "$(dirname "$NANOBOT_DIR")" \
            "${EXCLUDES[@]}" \
            "$(basename "$NANOBOT_DIR")"
        log "Backup saved to $BACKUP_DIR/nanobot-$HOSTNAME-$DATE.tar.gz"
        ;;

    restic)
        if ! command -v restic &>/dev/null; then
            log "ERROR: restic not installed"
            exit 1
        fi
        if [[ -z "${RESTIC_REPOSITORY:-}" || -z "${RESTIC_PASSWORD:-}" ]]; then
            log "ERROR: RESTIC_REPOSITORY and RESTIC_PASSWORD must be set"
            exit 1
        fi
        log "Running restic backup..."
        restic backup "${EXCLUDES[@]}" "$NANOBOT_DIR"
        log "Running restic forget/prune (keep 7d/4w/6m)..."
        restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
        log "Restic backup complete"
        ;;

    rsync)
        if [[ -z "${RSYNC_DEST:-}" ]]; then
            log "ERROR: RSYNC_DEST must be set (e.g., user@host:/path)"
            exit 1
        fi
        log "Running rsync to $RSYNC_DEST..."
        rsync -avz --delete "${EXCLUDES[@]}" "$NANOBOT_DIR/" "$RSYNC_DEST/"
        log "Rsync complete"
        ;;

    borg)
        if ! command -v borg &>/dev/null; then
            log "ERROR: borg not installed"
            exit 1
        fi
        if [[ -z "${BORG_REPO:-}" || -z "${BORG_PASSPHRASE:-}" ]]; then
            log "ERROR: BORG_REPO and BORG_PASSPHRASE must be set"
            exit 1
        fi
        log "Running borg backup..."
        borg create --compression lz4 "${EXCLUDES[@]}" \
            "$BORG_REPO::nanobot-$HOSTNAME-$DATE" \
            "$NANOBOT_DIR"
        log "Running borg prune (keep 7d/4w/6m)..."
        borg prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6 "$BORG_REPO"
        log "Borg backup complete"
        ;;

    *)
        log "ERROR: Unknown method '$METHOD'. Use: tar|restic|rsync|borg"
        exit 1
        ;;
esac

log "Backup completed successfully"