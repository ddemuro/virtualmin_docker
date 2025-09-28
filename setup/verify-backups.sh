#!/bin/bash
# Backup Verification Script

set -e

BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"
VERIFICATION_LOG="${BACKUP_ROOT}/verification.log"

echo "=========================================" | tee -a "$VERIFICATION_LOG"
echo "Backup Verification: $(date)" | tee -a "$VERIFICATION_LOG"
echo "=========================================" | tee -a "$VERIFICATION_LOG"

errors=0
warnings=0

# Function to check backup age
check_backup_age() {
    local backup_dir=$1
    local max_age_hours=$2
    local backup_type=$3

    latest_backup=$(find "$backup_dir" -type f -name "*.gz" -o -name "*.tar.gz" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)

    if [ -z "$latest_backup" ]; then
        echo "ERROR: No $backup_type backups found in $backup_dir" | tee -a "$VERIFICATION_LOG"
        errors=$((errors + 1))
        return 1
    fi

    age_minutes=$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 60 ))
    age_hours=$(( age_minutes / 60 ))

    if [ $age_minutes -gt $((max_age_hours * 60)) ]; then
        echo "ERROR: Latest $backup_type backup is $age_hours hours old (max: $max_age_hours hours)" | tee -a "$VERIFICATION_LOG"
        errors=$((errors + 1))
        return 1
    else
        echo "OK: Latest $backup_type backup is $age_hours hours old" | tee -a "$VERIFICATION_LOG"
        return 0
    fi
}

# Function to verify backup integrity
verify_backup_integrity() {
    local backup_file=$1

    if [ ! -f "$backup_file" ]; then
        return 1
    fi

    case "$backup_file" in
        *.sql.gz)
            if gzip -t "$backup_file" 2>/dev/null; then
                # Try to check SQL syntax (first few lines)
                if zcat "$backup_file" | head -100 | grep -q "MySQL dump\|MariaDB dump"; then
                    return 0
                else
                    echo "WARNING: $backup_file may not be a valid SQL dump" | tee -a "$VERIFICATION_LOG"
                    warnings=$((warnings + 1))
                    return 1
                fi
            else
                echo "ERROR: $backup_file is corrupted" | tee -a "$VERIFICATION_LOG"
                errors=$((errors + 1))
                return 1
            fi
            ;;
        *.tar.gz)
            if tar -tzf "$backup_file" >/dev/null 2>&1; then
                return 0
            else
                echo "ERROR: $backup_file is corrupted" | tee -a "$VERIFICATION_LOG"
                errors=$((errors + 1))
                return 1
            fi
            ;;
        *.ldif.gz)
            if gzip -t "$backup_file" 2>/dev/null; then
                return 0
            else
                echo "ERROR: $backup_file is corrupted" | tee -a "$VERIFICATION_LOG"
                errors=$((errors + 1))
                return 1
            fi
            ;;
    esac
}

# Check daily backups (should be less than 26 hours old)
echo "Checking daily backups..." | tee -a "$VERIFICATION_LOG"
check_backup_age "${BACKUP_ROOT}/daily" 26 "daily"

# Check quick backups (should be less than 7 hours old)
echo "Checking quick backups..." | tee -a "$VERIFICATION_LOG"
check_backup_age "${BACKUP_ROOT}/quick" 7 "quick configuration"

# Check MySQL backups (should be less than 5 hours old)
echo "Checking MySQL backups..." | tee -a "$VERIFICATION_LOG"
check_backup_age "${BACKUP_ROOT}/mysql" 5 "MySQL"

# Verify integrity of recent backups
echo "Verifying backup integrity..." | tee -a "$VERIFICATION_LOG"

# Check today's daily backups
for backup in $(find "${BACKUP_ROOT}/daily" -type f -mtime -1 2>/dev/null); do
    echo -n "Verifying $(basename "$backup")... " | tee -a "$VERIFICATION_LOG"
    if verify_backup_integrity "$backup"; then
        echo "OK" | tee -a "$VERIFICATION_LOG"
    else
        echo "FAILED" | tee -a "$VERIFICATION_LOG"
    fi
done

# Check disk space
echo "Checking disk space..." | tee -a "$VERIFICATION_LOG"
backup_usage=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$backup_usage" -gt 80 ]; then
    echo "WARNING: Backup disk usage is ${backup_usage}%" | tee -a "$VERIFICATION_LOG"
    warnings=$((warnings + 1))
elif [ "$backup_usage" -gt 90 ]; then
    echo "ERROR: Backup disk usage is ${backup_usage}%" | tee -a "$VERIFICATION_LOG"
    errors=$((errors + 1))
else
    echo "OK: Backup disk usage is ${backup_usage}%" | tee -a "$VERIFICATION_LOG"
fi

# Check backup sizes (alert if backup is unusually small)
echo "Checking backup sizes..." | tee -a "$VERIFICATION_LOG"
for backup_type in "mysql" "virtualmin" "websites" "mail"; do
    latest=$(find "${BACKUP_ROOT}/daily" -name "${backup_type}-*.gz" -o -name "${backup_type}-*.tar.gz" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        size=$(du -h "$latest" | cut -f1)
        size_bytes=$(stat -c %s "$latest")

        # Alert if backup is smaller than 1KB (probably empty)
        if [ "$size_bytes" -lt 1024 ]; then
            echo "ERROR: $backup_type backup is too small ($size)" | tee -a "$VERIFICATION_LOG"
            errors=$((errors + 1))
        else
            echo "OK: $backup_type backup size is $size" | tee -a "$VERIFICATION_LOG"
        fi
    fi
done

# Summary
echo "=========================================" | tee -a "$VERIFICATION_LOG"
echo "Verification Summary:" | tee -a "$VERIFICATION_LOG"
echo "Errors: $errors" | tee -a "$VERIFICATION_LOG"
echo "Warnings: $warnings" | tee -a "$VERIFICATION_LOG"

if [ $errors -gt 0 ]; then
    echo "STATUS: FAILED" | tee -a "$VERIFICATION_LOG"
    # Send alert email if configured
    if [ -n "$ALERT_EMAIL" ] && [ "$ALERT_EMAIL" != "admin@example.com" ]; then
        echo "Backup verification FAILED with $errors errors. Check $VERIFICATION_LOG for details." | \
            mail -s "[ALERT] Backup Verification Failed - $(hostname)" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    exit 1
elif [ $warnings -gt 0 ]; then
    echo "STATUS: PASSED WITH WARNINGS" | tee -a "$VERIFICATION_LOG"
    exit 0
else
    echo "STATUS: PASSED" | tee -a "$VERIFICATION_LOG"
    exit 0
fi