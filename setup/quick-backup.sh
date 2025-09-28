#!/bin/bash
# Quick Configuration Backup Script
# Backs up only configuration files, not data

set -e

BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
QUICK_DIR="${BACKUP_ROOT}/quick"

mkdir -p "$QUICK_DIR"

echo "[$(date)] Starting quick configuration backup..."

# Create a single archive with all configs
tar -czf "${QUICK_DIR}/configs-${BACKUP_DATE}.tar.gz" \
    /etc/apache2 \
    /etc/php \
    /etc/mysql \
    /etc/postfix \
    /etc/dovecot \
    /etc/bind \
    /etc/webmin \
    /etc/usermin \
    /etc/fail2ban \
    /etc/clamav \
    /etc/ssh \
    /etc/ssl \
    /etc/letsencrypt \
    /etc/cron.d \
    /etc/crontab \
    --exclude='*.pid' \
    --exclude='*.sock' \
    --exclude='*.lock' \
    2>/dev/null || true

# Keep only last 24 quick backups (every 6 hours = 4 per day * 6 days)
find "$QUICK_DIR" -type f -name "configs-*.tar.gz" | sort -r | tail -n +25 | xargs rm -f 2>/dev/null || true

echo "[$(date)] Quick configuration backup completed: ${QUICK_DIR}/configs-${BACKUP_DATE}.tar.gz"