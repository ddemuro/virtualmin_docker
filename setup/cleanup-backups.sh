#!/bin/bash
# Backup Cleanup Script

set -e

BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
RETENTION_DAILY="${BACKUP_RETENTION_DAYS:-7}"
RETENTION_WEEKLY="${BACKUP_RETENTION_WEEKLY:-4}"
RETENTION_MONTHLY="${BACKUP_RETENTION_MONTHLY:-3}"

echo "========================================="
echo "Backup Cleanup: $(date)"
echo "========================================="

# Function to cleanup directory
cleanup_directory() {
    local dir=$1
    local retention=$2
    local type=$3

    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist, skipping..."
        return
    fi

    echo "Cleaning $type backups in $dir (keeping last $retention)..."

    # Count files before cleanup
    before_count=$(find "$dir" -type f | wc -l)
    before_size=$(du -sh "$dir" 2>/dev/null | cut -f1)

    # Remove old files
    find "$dir" -type f -mtime +${retention} -delete 2>/dev/null || true

    # Count files after cleanup
    after_count=$(find "$dir" -type f | wc -l)
    after_size=$(du -sh "$dir" 2>/dev/null | cut -f1)

    deleted=$((before_count - after_count))
    echo "  Deleted $deleted files"
    echo "  Size: $before_size -> $after_size"
}

# Clean daily backups
cleanup_directory "${BACKUP_ROOT}/daily" "$RETENTION_DAILY" "daily"

# Clean weekly backups (convert weeks to days)
cleanup_directory "${BACKUP_ROOT}/weekly" "$((RETENTION_WEEKLY * 7))" "weekly"

# Clean monthly backups (convert months to days)
cleanup_directory "${BACKUP_ROOT}/monthly" "$((RETENTION_MONTHLY * 30))" "monthly"

# Clean quick backups (keep 2 days)
cleanup_directory "${BACKUP_ROOT}/quick" "2" "quick"

# Clean MySQL incremental backups (keep 2 days)
cleanup_directory "${BACKUP_ROOT}/mysql" "2" "MySQL incremental"

# Remove empty directories
echo "Removing empty directories..."
find "$BACKUP_ROOT" -type d -empty -delete 2>/dev/null || true

# Clean old log files (keep 30 days)
echo "Cleaning old log files..."
find "$BACKUP_ROOT" -name "*.log" -mtime +30 -delete 2>/dev/null || true

# Display disk usage
echo ""
echo "Current backup disk usage:"
df -h "$BACKUP_ROOT"
echo ""
echo "Backup directory sizes:"
du -sh ${BACKUP_ROOT}/* 2>/dev/null || true

echo "========================================="
echo "Cleanup completed: $(date)"
echo "========================================="