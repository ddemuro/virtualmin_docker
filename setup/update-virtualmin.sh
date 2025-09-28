#!/bin/bash
# Virtualmin Update Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Virtualmin Update Utility${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Virtualmin is installed
if ! command -v virtualmin &> /dev/null; then
    echo -e "${RED}Virtualmin is not installed!${NC}"
    exit 1
fi

# Create backup before updating
BACKUP_DIR="/data/updates/virtualmin-backup-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}Creating Virtualmin backup at ${BACKUP_DIR}...${NC}"
mkdir -p "${BACKUP_DIR}"

# Backup Virtualmin configuration
cp -r /etc/webmin "${BACKUP_DIR}/" 2>/dev/null || true
cp -r /etc/usermin "${BACKUP_DIR}/" 2>/dev/null || true
virtualmin backup-config --dest "${BACKUP_DIR}/virtualmin-config.tar.gz" 2>/dev/null || true

echo -e "${GREEN}Backup completed${NC}"

# Update Virtualmin repositories
echo -e "${YELLOW}Updating Virtualmin repositories...${NC}"
apt-get update

# Check current version
CURRENT_VERSION=$(virtualmin version 2>/dev/null || echo "Unknown")
echo -e "${YELLOW}Current Virtualmin version: ${CURRENT_VERSION}${NC}"

# Update Webmin/Virtualmin packages
echo -e "${YELLOW}Updating Webmin/Virtualmin packages...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade \
    webmin \
    usermin \
    virtualmin-core \
    virtualmin-config \
    webmin-virtual-server \
    webmin-virtualmin-awstats \
    webmin-virtualmin-htpasswd \
    webmin-virtualmin-mailman || true

# Update Virtualmin theme
echo -e "${YELLOW}Updating Virtualmin theme...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade \
    webmin-theme-authentic \
    webmin-authentic-theme || true

# Update Virtualmin modules
echo -e "${YELLOW}Updating Virtualmin modules...${NC}"
virtualmin install-module --all 2>/dev/null || true

# Refresh Virtualmin configuration
echo -e "${YELLOW}Refreshing Virtualmin configuration...${NC}"
virtualmin refresh-config 2>/dev/null || true

# Check for configuration issues
echo -e "${YELLOW}Checking configuration...${NC}"
virtualmin check-config 2>/dev/null || true

# Update virus definitions
echo -e "${YELLOW}Updating virus definitions...${NC}"
freshclam --quiet || true

# Update SpamAssassin rules
echo -e "${YELLOW}Updating SpamAssassin rules...${NC}"
sa-update || true

# Get new version
NEW_VERSION=$(virtualmin version 2>/dev/null || echo "Unknown")
echo -e "${GREEN}New Virtualmin version: ${NEW_VERSION}${NC}"

# Log the update
echo "$(date): Virtualmin updated from ${CURRENT_VERSION} to ${NEW_VERSION}" >> /var/log/virtualmin/updates.log

# Restart Webmin/Virtualmin
echo -e "${YELLOW}Restarting Webmin/Virtualmin...${NC}"
service webmin restart || /etc/init.d/webmin restart || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Virtualmin update completed!${NC}"
echo -e "${GREEN}Backup stored at: ${BACKUP_DIR}${NC}"
echo -e "${GREEN}Access Virtualmin at: https://$(hostname -I | cut -d' ' -f1):10000${NC}"
echo -e "${GREEN}========================================${NC}"