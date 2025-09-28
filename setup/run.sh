#!/bin/bash
set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Virtualmin Container${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to check if a service is running
check_service() {
    if pgrep -x "$1" > /dev/null; then
        echo -e "${GREEN}✓ $1 is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 is not running${NC}"
        return 1
    fi
}

# Function to start a service safely
start_service() {
    local service=$1
    echo -e "${YELLOW}Starting $service...${NC}"

    if [ -f /usr/bin/systemctl.py ]; then
        /usr/bin/systemctl.py start "$service" 2>/dev/null || true
    else
        service "$service" start 2>/dev/null || true
    fi

    sleep 2

    if check_service "$service"; then
        return 0
    else
        echo -e "${RED}Failed to start $service${NC}"
        return 1
    fi
}

# Initialize system
echo -e "${YELLOW}Initializing system...${NC}"

# Create necessary directories if they don't exist
mkdir -p /var/run/sshd
mkdir -p /var/run/apache2
mkdir -p /var/run/php
mkdir -p /var/run/dovecot
mkdir -p /var/run/mysqld
mkdir -p /var/log/apache2
mkdir -p /var/log/mysql
mkdir -p /var/log/mail
mkdir -p /var/log/virtualmin

# Set proper permissions
chmod 755 /var/run/sshd
chown mysql:mysql /var/run/mysqld 2>/dev/null || true

# Initialize databases if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo -e "${YELLOW}Initializing MySQL database...${NC}"
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi

# Start essential services
echo -e "${YELLOW}Starting essential services...${NC}"

# Start cron
start_service cron

# Start SSH
start_service ssh

# Start MySQL/MariaDB
start_service mysql || start_service mariadb

# Start Postfix
start_service postfix

# Start Dovecot
start_service dovecot

# Start BIND9
start_service bind9 || start_service named

# Start Apache2
start_service apache2

# Start PHP-FPM services for all installed versions
for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
    if [ -f "/etc/init.d/php${version}-fpm" ]; then
        start_service "php${version}-fpm"
    fi
done

# Start Webmin/Virtualmin
if [ -f /etc/init.d/webmin ]; then
    start_service webmin
fi

# Start fail2ban
start_service fail2ban

# Start ClamAV
start_service clamav-daemon
start_service clamav-freshclam

# Function to handle container shutdown
shutdown_handler() {
    echo -e "${YELLOW}Shutting down services gracefully...${NC}"

    # Stop services in reverse order
    service webmin stop 2>/dev/null || true
    service apache2 stop 2>/dev/null || true

    for version in 8.3 8.2 8.1 8.0 7.4 7.3 7.2 7.1 7.0 5.6; do
        service "php${version}-fpm" stop 2>/dev/null || true
    done

    service dovecot stop 2>/dev/null || true
    service postfix stop 2>/dev/null || true
    service mysql stop 2>/dev/null || true
    service bind9 stop 2>/dev/null || true
    service ssh stop 2>/dev/null || true
    service cron stop 2>/dev/null || true

    exit 0
}

# Setup signal handlers
trap shutdown_handler SIGTERM SIGINT

# Create a marker file to indicate container is ready
touch /var/run/container_ready

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Container initialization complete!${NC}"
echo -e "${GREEN}Virtualmin: https://$(hostname -I | cut -d' ' -f1):10000${NC}"
echo -e "${GREEN}========================================${NC}"

# Keep container running and monitor services
while true; do
    # Check critical services every 30 seconds
    sleep 30

    # Restart critical services if they've stopped
    for service in apache2 mysql postfix dovecot; do
        if ! pgrep -x "$service" > /dev/null; then
            echo -e "${YELLOW}Service $service stopped, attempting restart...${NC}"
            start_service "$service"
        fi
    done
done