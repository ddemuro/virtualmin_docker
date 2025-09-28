#!/bin/bash
# Automated Backup Script for Virtualmin Docker
# Runs via cron to backup all critical services

set -e

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DAY=$(date +%A)
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
BACKUP_RETENTION_WEEKLY="${BACKUP_RETENTION_WEEKLY:-4}"
BACKUP_RETENTION_MONTHLY="${BACKUP_RETENTION_MONTHLY:-3}"

# Backup directories
DAILY_DIR="${BACKUP_ROOT}/daily"
WEEKLY_DIR="${BACKUP_ROOT}/weekly"
MONTHLY_DIR="${BACKUP_ROOT}/monthly"

# Create backup directories
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR"

# Logging
LOG_FILE="${BACKUP_ROOT}/backup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=========================================="
echo "Automated Backup Started: $(date)"
echo "=========================================="

# Function to backup MySQL/MariaDB
backup_mysql() {
    echo "[$(date +%H:%M:%S)] Backing up MySQL databases..."

    local backup_file="${DAILY_DIR}/mysql-${BACKUP_DATE}.sql.gz"

    # Check if MySQL is running
    if pgrep -x "mysqld" > /dev/null || pgrep -x "mariadb" > /dev/null; then
        # Backup all databases
        mysqldump --all-databases \
            --single-transaction \
            --routines \
            --triggers \
            --events \
            --add-drop-database \
            --compress \
            --hex-blob \
            --user=root \
            --password="${MYSQL_ROOT_PASSWORD}" \
            2>/dev/null | gzip -9 > "$backup_file"

        if [ $? -eq 0 ]; then
            echo "[$(date +%H:%M:%S)] ✓ MySQL backup completed: $(du -h "$backup_file" | cut -f1)"
        else
            echo "[$(date +%H:%M:%S)] ✗ MySQL backup failed"
            return 1
        fi
    else
        echo "[$(date +%H:%M:%S)] ⚠ MySQL not running, skipping"
    fi
}

# Function to backup LDAP/SLAPD
backup_ldap() {
    echo "[$(date +%H:%M:%S)] Backing up LDAP directory..."

    local backup_file="${DAILY_DIR}/ldap-${BACKUP_DATE}.ldif.gz"

    # Check if LDAP is accessible
    if ldapsearch -x -LLL -b "dc=example,dc=com" >/dev/null 2>&1; then
        # Export LDAP data
        slapcat -n 1 2>/dev/null | gzip -9 > "$backup_file" || \
        ldapsearch -x -LLL -b "dc=example,dc=com" -D "cn=admin,dc=example,dc=com" \
            -w "${LDAP_ADMIN_PASSWORD}" \
            "*" "+" 2>/dev/null | gzip -9 > "$backup_file"

        if [ $? -eq 0 ]; then
            echo "[$(date +%H:%M:%S)] ✓ LDAP backup completed: $(du -h "$backup_file" | cut -f1)"
        else
            echo "[$(date +%H:%M:%S)] ✗ LDAP backup failed"
        fi
    else
        echo "[$(date +%H:%M:%S)] ⚠ LDAP not accessible, skipping"
    fi
}

# Function to backup Virtualmin configuration
backup_virtualmin() {
    echo "[$(date +%H:%M:%S)] Backing up Virtualmin configuration..."

    local backup_file="${DAILY_DIR}/virtualmin-config-${BACKUP_DATE}.tar.gz"

    # Backup Webmin/Virtualmin configs
    tar -czf "$backup_file" \
        /etc/webmin \
        /etc/usermin \
        /etc/virtualmin-license \
        2>/dev/null || true

    # Backup virtual servers if virtualmin command exists
    if command -v virtualmin &> /dev/null; then
        local domains_file="${DAILY_DIR}/virtualmin-domains-${BACKUP_DATE}.tar.gz"
        virtualmin backup-domain \
            --all-domains \
            --all-features \
            --dest "$domains_file" \
            --newformat \
            2>/dev/null || true
        echo "[$(date +%H:%M:%S)] ✓ Virtualmin domains backed up"
    fi

    echo "[$(date +%H:%M:%S)] ✓ Virtualmin config backup completed"
}

# Function to backup mail server data
backup_mail() {
    echo "[$(date +%H:%M:%S)] Backing up mail server data..."

    local backup_file="${DAILY_DIR}/mail-${BACKUP_DATE}.tar.gz"

    # Backup mail configurations and data
    tar -czf "$backup_file" \
        /etc/postfix \
        /etc/dovecot \
        /var/spool/postfix \
        /var/mail \
        /var/vmail \
        --exclude='*.pid' \
        --exclude='*.lock' \
        2>/dev/null || true

    if [ $? -eq 0 ]; then
        echo "[$(date +%H:%M:%S)] ✓ Mail backup completed: $(du -h "$backup_file" | cut -f1)"
    fi
}

# Function to backup web data
backup_websites() {
    echo "[$(date +%H:%M:%S)] Backing up website data..."

    local backup_file="${DAILY_DIR}/websites-${BACKUP_DATE}.tar.gz"

    # Backup all home directories (websites)
    tar -czf "$backup_file" \
        /home/*/public_html \
        /home/*/domains \
        --exclude='*/tmp/*' \
        --exclude='*/cache/*' \
        --exclude='*/logs/*' \
        --exclude='*.log' \
        2>/dev/null || true

    if [ $? -eq 0 ] && [ -f "$backup_file" ]; then
        echo "[$(date +%H:%M:%S)] ✓ Websites backup completed: $(du -h "$backup_file" | cut -f1)"
    fi
}

# Function to backup Apache configuration
backup_apache() {
    echo "[$(date +%H:%M:%S)] Backing up Apache configuration..."

    local backup_file="${DAILY_DIR}/apache-${BACKUP_DATE}.tar.gz"

    tar -czf "$backup_file" \
        /etc/apache2 \
        --exclude='*.pid' \
        2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ Apache backup completed"
}

# Function to backup PHP configurations
backup_php() {
    echo "[$(date +%H:%M:%S)] Backing up PHP configurations..."

    local backup_file="${DAILY_DIR}/php-${BACKUP_DATE}.tar.gz"

    tar -czf "$backup_file" \
        /etc/php \
        2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ PHP backup completed"
}

# Function to backup SSL certificates
backup_ssl() {
    echo "[$(date +%H:%M:%S)] Backing up SSL certificates..."

    local backup_file="${DAILY_DIR}/ssl-${BACKUP_DATE}.tar.gz"

    tar -czf "$backup_file" \
        /etc/letsencrypt \
        /etc/ssl/certs \
        /etc/ssl/private \
        2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ SSL certificates backup completed"
}

# Function to backup DNS zones
backup_dns() {
    echo "[$(date +%H:%M:%S)] Backing up DNS zones..."

    local backup_file="${DAILY_DIR}/dns-${BACKUP_DATE}.tar.gz"

    # Backup BIND configuration and zones
    tar -czf "$backup_file" \
        /etc/bind \
        /var/cache/bind \
        --exclude='*.jnl' \
        --exclude='*.pid' \
        2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ DNS backup completed"
}

# Function to backup fail2ban
backup_security() {
    echo "[$(date +%H:%M:%S)] Backing up security configurations..."

    local backup_file="${DAILY_DIR}/security-${BACKUP_DATE}.tar.gz"

    tar -czf "$backup_file" \
        /etc/fail2ban \
        /etc/clamav \
        /var/lib/fail2ban \
        --exclude='*.sock' \
        --exclude='*.pid' \
        2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ Security backup completed"
}

# Function to backup cron jobs
backup_cron() {
    echo "[$(date +%H:%M:%S)] Backing up cron jobs..."

    local backup_file="${DAILY_DIR}/cron-${BACKUP_DATE}.tar.gz"

    # Backup all cron related files
    tar -czf "$backup_file" \
        /etc/cron.d \
        /etc/cron.daily \
        /etc/cron.hourly \
        /etc/cron.monthly \
        /etc/cron.weekly \
        /etc/crontab \
        /var/spool/cron \
        2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ Cron backup completed"
}

# Function to create metadata file
create_metadata() {
    local metadata_file="${DAILY_DIR}/backup-metadata-${BACKUP_DATE}.json"

    cat > "$metadata_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "date": "${BACKUP_DATE}",
    "hostname": "$(hostname)",
    "os_version": "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)",
    "virtualmin_version": "$(virtualmin version 2>/dev/null || echo 'N/A')",
    "mysql_version": "$(mysql --version 2>/dev/null | cut -d' ' -f6 || echo 'N/A')",
    "apache_version": "$(apache2 -v 2>/dev/null | head -1 | cut -d' ' -f3 || echo 'N/A')",
    "backup_size": "$(du -sh ${DAILY_DIR}/*${BACKUP_DATE}* 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo '0')",
    "backup_files": [
$(ls -1 ${DAILY_DIR}/*${BACKUP_DATE}* 2>/dev/null | sed 's/^/        "/' | sed 's/$/",/' | sed '$ s/,$//')
    ]
}
EOF

    echo "[$(date +%H:%M:%S)] ✓ Metadata file created"
}

# Function to rotate backups
rotate_backups() {
    echo "[$(date +%H:%M:%S)] Rotating backups..."

    # Copy to weekly on Sunday
    if [ "$(date +%u)" = "7" ]; then
        echo "[$(date +%H:%M:%S)] Creating weekly backup..."
        cp -a ${DAILY_DIR}/*${BACKUP_DATE}* "$WEEKLY_DIR/" 2>/dev/null || true
    fi

    # Copy to monthly on 1st day of month
    if [ "$(date +%d)" = "01" ]; then
        echo "[$(date +%H:%M:%S)] Creating monthly backup..."
        cp -a ${DAILY_DIR}/*${BACKUP_DATE}* "$MONTHLY_DIR/" 2>/dev/null || true
    fi

    # Remove old daily backups
    echo "[$(date +%H:%M:%S)] Cleaning old daily backups (keeping ${BACKUP_RETENTION_DAYS} days)..."
    find "$DAILY_DIR" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete 2>/dev/null || true

    # Remove old weekly backups
    echo "[$(date +%H:%M:%S)] Cleaning old weekly backups (keeping ${BACKUP_RETENTION_WEEKLY} weeks)..."
    find "$WEEKLY_DIR" -type f -mtime +$((BACKUP_RETENTION_WEEKLY * 7)) -delete 2>/dev/null || true

    # Remove old monthly backups
    echo "[$(date +%H:%M:%S)] Cleaning old monthly backups (keeping ${BACKUP_RETENTION_MONTHLY} months)..."
    find "$MONTHLY_DIR" -type f -mtime +$((BACKUP_RETENTION_MONTHLY * 30)) -delete 2>/dev/null || true

    echo "[$(date +%H:%M:%S)] ✓ Backup rotation completed"
}

# Function to send notification (optional)
send_notification() {
    local status=$1
    local message=$2

    # You can implement email notification here if needed
    # For now, just log it
    echo "[$(date +%H:%M:%S)] Notification: $status - $message"

    # Example email notification (uncomment and configure if needed)
    # echo "$message" | mail -s "Backup $status - $(hostname)" admin@example.com
}

# Function to check backup integrity
verify_backups() {
    echo "[$(date +%H:%M:%S)] Verifying backup integrity..."

    local errors=0

    # Check each backup file created today
    for backup_file in ${DAILY_DIR}/*${BACKUP_DATE}*; do
        if [ -f "$backup_file" ]; then
            # Check if file is not empty
            if [ ! -s "$backup_file" ]; then
                echo "[$(date +%H:%M:%S)] ✗ Empty backup file: $backup_file"
                errors=$((errors + 1))
                continue
            fi

            # Check if compressed files are valid
            case "$backup_file" in
                *.gz)
                    if ! gzip -t "$backup_file" 2>/dev/null; then
                        echo "[$(date +%H:%M:%S)] ✗ Corrupted gzip file: $backup_file"
                        errors=$((errors + 1))
                    fi
                    ;;
                *.tar.gz)
                    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
                        echo "[$(date +%H:%M:%S)] ✗ Corrupted tar.gz file: $backup_file"
                        errors=$((errors + 1))
                    fi
                    ;;
            esac
        fi
    done

    if [ $errors -eq 0 ]; then
        echo "[$(date +%H:%M:%S)] ✓ All backups verified successfully"
        return 0
    else
        echo "[$(date +%H:%M:%S)] ✗ Backup verification failed with $errors errors"
        return 1
    fi
}

# Main backup execution
main() {
    # Start backups
    echo "[$(date +%H:%M:%S)] Starting automated backup process..."

    # Run all backup functions
    backup_mysql
    backup_ldap
    backup_virtualmin
    backup_mail
    backup_websites
    backup_apache
    backup_php
    backup_ssl
    backup_dns
    backup_security
    backup_cron

    # Create metadata
    create_metadata

    # Verify backups
    if verify_backups; then
        backup_status="SUCCESS"
    else
        backup_status="FAILED"
    fi

    # Rotate old backups
    rotate_backups

    # Calculate total backup size
    total_size=$(du -sh "$DAILY_DIR" | cut -f1)

    # Send notification
    send_notification "$backup_status" "Backup completed. Total size: $total_size"

    echo "=========================================="
    echo "Backup Status: $backup_status"
    echo "Total Backup Size: $total_size"
    echo "Backup Location: $BACKUP_ROOT"
    echo "Completed: $(date)"
    echo "=========================================="

    # Exit with appropriate status
    [ "$backup_status" = "SUCCESS" ] && exit 0 || exit 1
}

# Run main function
main "$@"