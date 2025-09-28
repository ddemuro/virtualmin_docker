#!/bin/bash
# Container Restore Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Container Restore Utility${NC}"
echo -e "${GREEN}========================================${NC}"

# Check arguments
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No backup file specified${NC}"
    echo "Usage: $0 /path/to/backup.tar.gz [--force]"
    echo ""
    echo "Available backups:"
    ls -lh /data/backups/*.tar.gz 2>/dev/null || echo "No backups found in /data/backups/"
    exit 1
fi

BACKUP_FILE="$1"
FORCE_RESTORE=false

# Parse additional arguments
if [ "$2" = "--force" ]; then
    FORCE_RESTORE=true
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
    exit 1
fi

# Create temporary restore directory
TEMP_DIR="/tmp/restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TEMP_DIR"

echo -e "${YELLOW}Extracting backup archive...${NC}"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Find the actual backup directory
BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d | grep -v "^$TEMP_DIR$" | head -n1)

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Invalid backup structure${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check manifest
if [ -f "$BACKUP_DIR/manifest.txt" ]; then
    echo -e "${BLUE}Backup Information:${NC}"
    cat "$BACKUP_DIR/manifest.txt"
    echo ""
fi

# Confirmation prompt
if [ "$FORCE_RESTORE" != true ]; then
    echo -e "${YELLOW}Warning: This will overwrite current configuration!${NC}"
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restore cancelled${NC}"
        rm -rf "$TEMP_DIR"
        exit 0
    fi
fi

# Create safety backup of current config
echo -e "${YELLOW}Creating safety backup of current configuration...${NC}"
/usr/local/bin/backup-container --name "pre-restore-safety"

# Stop all services
echo -e "${YELLOW}Stopping services...${NC}"
service apache2 stop 2>/dev/null || true
service mysql stop 2>/dev/null || true
service postfix stop 2>/dev/null || true
service dovecot stop 2>/dev/null || true
service bind9 stop 2>/dev/null || true
service webmin stop 2>/dev/null || true

# Function to restore a tar archive
restore_archive() {
    local archive=$1
    local destination=$2
    local desc=$3

    if [ -f "$archive" ]; then
        echo -e "${BLUE}Restoring ${desc}...${NC}"
        tar -xzf "$archive" -C "$destination" 2>/dev/null || true
        echo -e "${GREEN}✓ ${desc} restored${NC}"
    else
        echo -e "${YELLOW}⚠ ${desc} backup not found, skipping${NC}"
    fi
}

# Restore configurations
echo -e "${YELLOW}Restoring configurations...${NC}"
[ -f "$BACKUP_DIR/webmin.tar.gz" ] && tar -xzf "$BACKUP_DIR/webmin.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/usermin.tar.gz" ] && tar -xzf "$BACKUP_DIR/usermin.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/apache2.tar.gz" ] && tar -xzf "$BACKUP_DIR/apache2.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/php.tar.gz" ] && tar -xzf "$BACKUP_DIR/php.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/postfix.tar.gz" ] && tar -xzf "$BACKUP_DIR/postfix.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/dovecot.tar.gz" ] && tar -xzf "$BACKUP_DIR/dovecot.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/bind.tar.gz" ] && tar -xzf "$BACKUP_DIR/bind.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/mysql-conf.tar.gz" ] && tar -xzf "$BACKUP_DIR/mysql-conf.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/fail2ban.tar.gz" ] && tar -xzf "$BACKUP_DIR/fail2ban.tar.gz" -C /etc/
[ -f "$BACKUP_DIR/clamav.tar.gz" ] && tar -xzf "$BACKUP_DIR/clamav.tar.gz" -C /etc/

# Restore SSL certificates
[ -f "$BACKUP_DIR/letsencrypt.tar.gz" ] && tar -xzf "$BACKUP_DIR/letsencrypt.tar.gz" -C /etc/

# Start MySQL for database restore
echo -e "${YELLOW}Starting MySQL for database restore...${NC}"
service mysql start 2>/dev/null || service mariadb start 2>/dev/null || true
sleep 5

# Restore databases
if [ -f "$BACKUP_DIR/all-databases.sql" ]; then
    echo -e "${BLUE}Restoring databases...${NC}"
    mysql < "$BACKUP_DIR/all-databases.sql" 2>/dev/null || true
    echo -e "${GREEN}✓ Databases restored${NC}"
fi

# Restore Virtualmin domains
if [ -f "$BACKUP_DIR/virtualmin-domains.tar.gz" ] && command -v virtualmin &> /dev/null; then
    echo -e "${BLUE}Restoring Virtualmin domains...${NC}"
    virtualmin restore-domain --all-domains --all-features \
        --source "$BACKUP_DIR/virtualmin-domains.tar.gz" \
        --newformat 2>/dev/null || true
    echo -e "${GREEN}✓ Virtualmin domains restored${NC}"
fi

# Restore home directories if full backup
if [ -f "$BACKUP_DIR/home.tar.gz" ]; then
    echo -e "${BLUE}Restoring home directories...${NC}"
    tar -xzf "$BACKUP_DIR/home.tar.gz" -C /
    echo -e "${GREEN}✓ Home directories restored${NC}"
else
    # Restore individual site backups
    for site_backup in "$BACKUP_DIR"/site-*.tar.gz; do
        if [ -f "$site_backup" ]; then
            echo -e "${BLUE}Restoring site from $(basename "$site_backup")...${NC}"
            tar -xzf "$site_backup" -C /home/
        fi
    done
fi

# Restore mail data if present
[ -f "$BACKUP_DIR/mail.tar.gz" ] && tar -xzf "$BACKUP_DIR/mail.tar.gz" -C /var/
[ -f "$BACKUP_DIR/vmail.tar.gz" ] && tar -xzf "$BACKUP_DIR/vmail.tar.gz" -C /var/

# Fix permissions
echo -e "${YELLOW}Fixing permissions...${NC}"
chown -R mysql:mysql /var/lib/mysql 2>/dev/null || true
chown -R www-data:www-data /var/www 2>/dev/null || true
chown -R root:root /etc/webmin 2>/dev/null || true
chmod 600 /etc/webmin/miniserv.conf 2>/dev/null || true

# Clean up
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"

# Restart all services
echo -e "${YELLOW}Starting services...${NC}"
service mysql start 2>/dev/null || service mariadb start 2>/dev/null || true
service bind9 start 2>/dev/null || service named start 2>/dev/null || true
service postfix start 2>/dev/null || true
service dovecot start 2>/dev/null || true
service apache2 start 2>/dev/null || true
service webmin start 2>/dev/null || true
service fail2ban start 2>/dev/null || true
service clamav-daemon start 2>/dev/null || true

# Start PHP-FPM services
for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
    if [ -f "/etc/init.d/php${version}-fpm" ]; then
        service "php${version}-fpm" start 2>/dev/null || true
    fi
done

# Verify Virtualmin configuration
echo -e "${YELLOW}Verifying configuration...${NC}"
virtualmin check-config 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Restore completed successfully!${NC}"
echo -e "${GREEN}Services have been restarted${NC}"
echo -e "${BLUE}Access Virtualmin at: https://$(hostname -I | cut -d' ' -f1):10000${NC}"
echo -e "${YELLOW}Note: You may need to restart the container for all changes to take effect${NC}"
echo -e "${GREEN}========================================${NC}"