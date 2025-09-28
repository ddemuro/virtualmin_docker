#!/bin/bash
# MySQL/MariaDB Incremental Backup Script

set -e

BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
MYSQL_BACKUP_DIR="${BACKUP_ROOT}/mysql"
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"

mkdir -p "$MYSQL_BACKUP_DIR"

echo "[$(date)] Starting MySQL incremental backup..."

# Check if MySQL is running
if ! pgrep -x "mysqld" > /dev/null && ! pgrep -x "mariadb" > /dev/null; then
    echo "[$(date)] MySQL/MariaDB is not running, skipping backup"
    exit 0
fi

# Get list of databases
DATABASES=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(Database|information_schema|performance_schema|sys|mysql)")

# Backup each database separately for easier restoration
for db in $DATABASES; do
    echo "[$(date)] Backing up database: $db"

    mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --quick \
        --lock-tables=false \
        "$db" 2>/dev/null | gzip -9 > "${MYSQL_BACKUP_DIR}/${db}-${BACKUP_DATE}.sql.gz"
done

# Also create a complete backup
mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" \
    --all-databases \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --quick \
    --lock-tables=false \
    2>/dev/null | gzip -9 > "${MYSQL_BACKUP_DIR}/all-databases-${BACKUP_DATE}.sql.gz"

# Binary log backup for point-in-time recovery (if enabled)
if [ -d "/var/lib/mysql" ]; then
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH LOGS;" 2>/dev/null || true

    # Copy binary logs
    cp /var/lib/mysql/mysql-bin.* "${MYSQL_BACKUP_DIR}/" 2>/dev/null || true
fi

# Keep only last 48 hours of incremental backups (12 backups if running every 4 hours)
find "$MYSQL_BACKUP_DIR" -type f -name "*-*.sql.gz" -mmin +2880 -delete 2>/dev/null || true

# Keep binary logs for 7 days
find "$MYSQL_BACKUP_DIR" -type f -name "mysql-bin.*" -mtime +7 -delete 2>/dev/null || true

echo "[$(date)] MySQL incremental backup completed"