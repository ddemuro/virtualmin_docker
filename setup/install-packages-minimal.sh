#!/bin/bash
# Minimal package installation for Virtualmin Docker
set -e

echo "========================================"
echo "Installing Essential Packages"
echo "========================================"

# Remove apt-listchanges if it exists to avoid errors
rm -f /usr/bin/apt-listchanges

# Update package lists
apt-get update

# Install web server first (required dependency for Virtualmin)
echo "Installing Apache..."
apt-get install -y \
    apache2 \
    apache2-utils \
    apache2-bin \
    apache2-data \
    libapache2-mod-fcgid

# Install Webmin/Virtualmin
echo "Installing Webmin/Virtualmin..."
apt-get install -y \
    webmin || echo "Webmin installation has warnings, continuing..."

apt-get install -y \
    webmin-virtual-server \
    webmin-virtualmin-awstats \
    webmin-virtualmin-dav || echo "Some Virtualmin modules failed, continuing..."

# Fix any broken dependencies
apt-get install -f -y || true

# Install mod-php for Apache
echo "Installing mod-php..."
apt-get install -y libapache2-mod-php || true

# Install PHP (default version)
echo "Installing PHP..."
apt-get install -y \
    php \
    php-cli \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip

# Install database server
echo "Installing MariaDB..."
apt-get install -y \
    mariadb-server \
    mariadb-client

# Install mail server
echo "Installing mail services..."
apt-get install -y \
    postfix \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d

# Install DNS server
echo "Installing BIND DNS..."
apt-get install -y \
    bind9 \
    bind9-utils

# Install LDAP
echo "Installing OpenLDAP..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    slapd \
    ldap-utils

# Install SSH server
echo "Installing SSH server..."
apt-get install -y \
    openssh-server

# Install essential tools
echo "Installing essential tools..."
apt-get install -y \
    supervisor \
    curl \
    wget \
    git \
    vim \
    net-tools \
    cron \
    fail2ban

echo "========================================"
echo "Package installation completed!"
echo "========================================"