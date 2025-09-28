#!/bin/bash
# Container Backup Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Container Backup Utility${NC}"
echo -e "${GREEN}========================================${NC}"

# Default backup location
BACKUP_ROOT="/data/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="virtualmin-backup-${TIMESTAMP}"
BACKUP_DIR="${BACKUP_ROOT}/${BACKUP_NAME}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_BACKUP=true
            shift
            ;;
        --dest)
            BACKUP_ROOT="$2"
            BACKUP_DIR="${BACKUP_ROOT}/${BACKUP_NAME}"
            shift 2
            ;;
        --name)
            BACKUP_NAME="$2"
            BACKUP_DIR="${BACKUP_ROOT}/${BACKUP_NAME}"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--full] [--dest /path/to/backup] [--name backup-name]"
            exit 1
            ;;
    esac
done

# Create backup directory
echo -e "${YELLOW}Creating backup directory: ${BACKUP_DIR}${NC}"
mkdir -p "${BACKUP_DIR}"

# Function to backup a directory with progress
backup_directory() {
    local src=$1
    local dest=$2
    local desc=$3

    if [ -d "$src" ]; then
        echo -e "${BLUE}Backing up ${desc}...${NC}"
        tar -czf "${dest}" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null || true
        echo -e "${GREEN}✓ ${desc} backed up${NC}"
    else
        echo -e "${YELLOW}⚠ ${desc} not found, skipping${NC}"
    fi
}

# Stop services for consistent backup
echo -e "${YELLOW}Stopping services for consistent backup...${NC}"
service cron stop 2>/dev/null || true

# Essential configuration backups
echo -e "${YELLOW}Backing up configurations...${NC}"
backup_directory "/etc/webmin" "${BACKUP_DIR}/webmin.tar.gz" "Webmin configuration"
backup_directory "/etc/usermin" "${BACKUP_DIR}/usermin.tar.gz" "Usermin configuration"
backup_directory "/etc/apache2" "${BACKUP_DIR}/apache2.tar.gz" "Apache configuration"
backup_directory "/etc/php" "${BACKUP_DIR}/php.tar.gz" "PHP configurations"
backup_directory "/etc/postfix" "${BACKUP_DIR}/postfix.tar.gz" "Postfix configuration"
backup_directory "/etc/dovecot" "${BACKUP_DIR}/dovecot.tar.gz" "Dovecot configuration"
backup_directory "/etc/bind" "${BACKUP_DIR}/bind.tar.gz" "BIND configuration"
backup_directory "/etc/mysql" "${BACKUP_DIR}/mysql-conf.tar.gz" "MySQL configuration"
backup_directory "/etc/fail2ban" "${BACKUP_DIR}/fail2ban.tar.gz" "Fail2ban configuration"
backup_directory "/etc/clamav" "${BACKUP_DIR}/clamav.tar.gz" "ClamAV configuration"

# Virtualmin domains and data
echo -e "${YELLOW}Backing up Virtualmin domains...${NC}"
if command -v virtualmin &> /dev/null; then
    virtualmin backup-domain --all-domains --all-features \
        --dest "${BACKUP_DIR}/virtualmin-domains.tar.gz" \
        --newformat 2>/dev/null || true
    echo -e "${GREEN}✓ Virtualmin domains backed up${NC}"
fi

# Backup home directories (websites)
if [ "$FULL_BACKUP" = true ]; then
    echo -e "${YELLOW}Performing full backup including all user data...${NC}"
    backup_directory "/home" "${BACKUP_DIR}/home.tar.gz" "Home directories"
else
    echo -e "${YELLOW}Backing up website configurations only...${NC}"
    # Just backup virtual server configs, not all data
    find /home -maxdepth 2 -name "public_html" -type d | while read dir; do
        username=$(echo "$dir" | cut -d'/' -f3)
        tar -czf "${BACKUP_DIR}/site-${username}.tar.gz" \
            -C /home "${username}/public_html" \
            "${username}/etc" \
            "${username}/logs" 2>/dev/null || true
    done
fi

# Backup databases
echo -e "${YELLOW}Backing up databases...${NC}"
if pgrep -x "mysqld" > /dev/null || pgrep -x "mariadb" > /dev/null; then
    mysqldump --all-databases --single-transaction --routines --triggers \
        > "${BACKUP_DIR}/all-databases.sql" 2>/dev/null || true
    echo -e "${GREEN}✓ Databases backed up${NC}"
else
    echo -e "${YELLOW}⚠ MySQL/MariaDB not running, skipping database backup${NC}"
fi

# Backup mail data
if [ "$FULL_BACKUP" = true ]; then
    backup_directory "/var/mail" "${BACKUP_DIR}/mail.tar.gz" "Mail data"
    backup_directory "/var/vmail" "${BACKUP_DIR}/vmail.tar.gz" "Virtual mail data"
fi

# Backup SSL certificates
backup_directory "/etc/letsencrypt" "${BACKUP_DIR}/letsencrypt.tar.gz" "SSL certificates"

# Create backup manifest
echo -e "${YELLOW}Creating backup manifest...${NC}"
cat > "${BACKUP_DIR}/manifest.txt" << EOF
Backup Created: $(date)
Hostname: $(hostname)
OS Version: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Virtualmin Version: $(virtualmin version 2>/dev/null || echo "N/A")
Backup Type: $([ "$FULL_BACKUP" = true ] && echo "Full" || echo "Configuration")

Contents:
$(ls -lh "${BACKUP_DIR}"/*.tar.gz 2>/dev/null || echo "No archives created")
$(ls -lh "${BACKUP_DIR}"/*.sql 2>/dev/null || echo "No SQL dumps created")
EOF

# Create compressed archive of entire backup
echo -e "${YELLOW}Creating final compressed archive...${NC}"
cd "${BACKUP_ROOT}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
FINAL_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

# Cleanup temporary backup directory
rm -rf "${BACKUP_DIR}"

# Restart services
echo -e "${YELLOW}Restarting services...${NC}"
service cron start 2>/dev/null || true

# Keep only last 7 backups
echo -e "${YELLOW}Cleaning old backups (keeping last 7)...${NC}"
cd "${BACKUP_ROOT}"
ls -t virtualmin-backup-*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${GREEN}Location: ${BACKUP_ROOT}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${GREEN}Size: ${FINAL_SIZE}${NC}"
echo -e "${BLUE}To restore, use: restore-container ${BACKUP_ROOT}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${GREEN}========================================${NC}"