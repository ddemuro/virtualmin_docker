#!/bin/bash
# OS Update Script for Virtualmin Container

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OS Update Utility${NC}"
echo -e "${GREEN}========================================${NC}"

# Create backup before updating
BACKUP_DIR="/data/updates/backup-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}Creating system backup at ${BACKUP_DIR}...${NC}"
mkdir -p "${BACKUP_DIR}"

# Backup critical configurations
cp -r /etc/apache2 "${BACKUP_DIR}/" 2>/dev/null || true
cp -r /etc/php "${BACKUP_DIR}/" 2>/dev/null || true
cp -r /etc/postfix "${BACKUP_DIR}/" 2>/dev/null || true
cp -r /etc/dovecot "${BACKUP_DIR}/" 2>/dev/null || true
cp -r /etc/bind "${BACKUP_DIR}/" 2>/dev/null || true
cp -r /etc/webmin "${BACKUP_DIR}/" 2>/dev/null || true

echo -e "${GREEN}Backup completed${NC}"

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
apt-get update

# Check for upgradable packages
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)

if [ "$UPGRADABLE" -eq 0 ]; then
    echo -e "${GREEN}System is already up to date!${NC}"
    exit 0
fi

echo -e "${YELLOW}Found ${UPGRADABLE} packages to upgrade${NC}"

# Show what will be upgraded
echo -e "${YELLOW}Packages to be upgraded:${NC}"
apt list --upgradable

# Ask for confirmation if running interactively
if [ -t 0 ]; then
    read -p "Do you want to continue with the upgrade? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update cancelled${NC}"
        exit 0
    fi
fi

# Perform the upgrade
echo -e "${YELLOW}Performing system upgrade...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Perform distribution upgrade if available
echo -e "${YELLOW}Checking for distribution upgrades...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
apt-get autoremove -y
apt-get autoclean -y

# Update ClamAV definitions
echo -e "${YELLOW}Updating ClamAV virus definitions...${NC}"
freshclam --quiet || true

# Log the update
echo "$(date): OS update completed" >> /var/log/virtualmin/updates.log

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OS update completed successfully!${NC}"
echo -e "${GREEN}Backup stored at: ${BACKUP_DIR}${NC}"
echo -e "${YELLOW}Note: Restart container for all changes to take effect${NC}"
echo -e "${GREEN}========================================${NC}"