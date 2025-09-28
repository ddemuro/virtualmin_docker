#!/bin/bash
# PHP Installation Script - All versions from 5.6 to 8.3
set -e

echo "========================================"
echo "Installing PHP Versions"
echo "========================================"

# Common PHP packages
echo "Installing common PHP packages..."
apt-get install -y \
    php-common \
    php-pear \
    dh-php

# Function to install PHP version with all modules
install_php_version() {
    local version=$1
    echo "========================================"
    echo "Installing PHP ${version}"
    echo "========================================"

    # Core PHP packages
    local packages="
        php${version}
        php${version}-cli
        php${version}-fpm
        php${version}-cgi
        php${version}-common
    "

    # Common extensions for all versions
    local common_extensions="
        php${version}-bcmath
        php${version}-bz2
        php${version}-curl
        php${version}-gd
        php${version}-intl
        php${version}-json
        php${version}-mbstring
        php${version}-mysql
        php${version}-opcache
        php${version}-readline
        php${version}-xml
        php${version}-zip
    "

    # Install core packages
    for package in $packages; do
        apt-get install -y $package 2>/dev/null || echo "Package $package not available"
    done

    # Install common extensions
    for extension in $common_extensions; do
        apt-get install -y $extension 2>/dev/null || echo "Extension $extension not available"
    done

    # Version-specific extensions
    case $version in
        5.6)
            apt-get install -y \
                php${version}-mcrypt \
                php${version}-mysql \
                libapache2-mod-php${version} \
                2>/dev/null || true
            ;;
        7.*)
            apt-get install -y \
                php${version}-mcrypt \
                libapache2-mod-php${version} \
                2>/dev/null || true
            ;;
        8.*)
            # mcrypt deprecated in PHP 8
            apt-get install -y \
                libapache2-mod-php${version} \
                2>/dev/null || true
            ;;
    esac

    echo "PHP ${version} installation completed"
}

# PHP 5.6 - Complete installation
echo "========================================"
echo "Installing PHP 5.6 (Legacy Support)"
echo "========================================"
apt-get install -y \
    php5.6 php5.6-amqp php5.6-apcu php5.6-bcmath php5.6-bz2 \
    php5.6-cgi php5.6-cli php5.6-common php5.6-curl php5.6-dba \
    php5.6-dev php5.6-enchant php5.6-fpm php5.6-gd php5.6-geoip \
    php5.6-gmp php5.6-igbinary php5.6-imagick php5.6-imap \
    php5.6-interbase php5.6-intl php5.6-json php5.6-ldap \
    php5.6-mbstring php5.6-mcrypt php5.6-memcache php5.6-memcached \
    php5.6-mongo php5.6-msgpack php5.6-mysql php5.6-odbc \
    php5.6-opcache php5.6-pgsql php5.6-phpdbg php5.6-pspell \
    php5.6-raphf php5.6-readline php5.6-recode php5.6-redis \
    php5.6-rrd php5.6-snmp php5.6-soap php5.6-solr php5.6-sqlite3 \
    php5.6-ssh2 php5.6-sybase php5.6-tidy php5.6-uploadprogress \
    php5.6-xdebug php5.6-xml php5.6-xmlrpc php5.6-xsl php5.6-zip \
    libapache2-mod-php5.6 2>/dev/null || echo "Some PHP 5.6 packages not available"

# PHP 7.0
echo "========================================"
echo "Installing PHP 7.0"
echo "========================================"
apt-get install -y \
    php7.0 php7.0-amqp php7.0-apcu php7.0-apcu-bc php7.0-ast \
    php7.0-bcmath php7.0-bz2 php7.0-cgi php7.0-cli php7.0-common \
    php7.0-curl php7.0-dba php7.0-dev php7.0-enchant php7.0-fpm \
    php7.0-gd php7.0-geoip php7.0-gmp php7.0-igbinary php7.0-imagick \
    php7.0-imap php7.0-interbase php7.0-intl php7.0-json php7.0-ldap \
    php7.0-libvirt-php php7.0-lz4 php7.0-mbstring php7.0-mcrypt \
    php7.0-memcache php7.0-memcached php7.0-mongodb php7.0-msgpack \
    php7.0-mysql php7.0-odbc php7.0-opcache php7.0-pgsql php7.0-phpdbg \
    php7.0-pspell php7.0-raphf php7.0-readline php7.0-recode \
    php7.0-redis php7.0-rrd php7.0-snmp php7.0-soap php7.0-solr \
    php7.0-sqlite3 php7.0-ssh2 php7.0-tidy php7.0-uploadprogress \
    php7.0-uuid php7.0-xdebug php7.0-xml php7.0-xmlrpc php7.0-xsl \
    php7.0-zip libapache2-mod-php7.0 2>/dev/null || echo "Some PHP 7.0 packages not available"

# PHP 7.1
echo "========================================"
echo "Installing PHP 7.1"
echo "========================================"
apt-get install -y \
    php7.1 php7.1-amqp php7.1-apcu php7.1-apcu-bc php7.1-ast \
    php7.1-bcmath php7.1-bz2 php7.1-cgi php7.1-cli php7.1-common \
    php7.1-curl php7.1-dba php7.1-decimal php7.1-dev php7.1-fpm \
    php7.1-gd php7.1-geoip php7.1-gmp php7.1-grpc php7.1-igbinary \
    php7.1-imagick php7.1-intl php7.1-json php7.1-libvirt-php \
    php7.1-lz4 php7.1-mbstring php7.1-mcrypt php7.1-memcache \
    php7.1-memcached php7.1-mongodb php7.1-msgpack php7.1-mysql \
    php7.1-odbc php7.1-opcache php7.1-pspell php7.1-raphf \
    php7.1-readline php7.1-recode php7.1-redis php7.1-rrd \
    php7.1-solr php7.1-sqlite3 php7.1-ssh2 php7.1-tidy \
    php7.1-uploadprogress php7.1-uuid php7.1-xdebug php7.1-xml \
    php7.1-xmlrpc php7.1-zip libapache2-mod-php7.1 2>/dev/null || echo "Some PHP 7.1 packages not available"

# PHP 7.2
echo "========================================"
echo "Installing PHP 7.2"
echo "========================================"
apt-get install -y \
    php7.2 php7.2-amqp php7.2-apcu php7.2-apcu-bc php7.2-ast \
    php7.2-bcmath php7.2-bz2 php7.2-cgi php7.2-cli php7.2-common \
    php7.2-curl php7.2-dba php7.2-decimal php7.2-dev php7.2-ds \
    php7.2-enchant php7.2-fpm php7.2-gd php7.2-geoip php7.2-gmp \
    php7.2-igbinary php7.2-imagick php7.2-imap php7.2-inotify \
    php7.2-interbase php7.2-intl php7.2-json php7.2-ldap \
    php7.2-libvirt-php php7.2-lz4 php7.2-mbstring php7.2-mcrypt \
    php7.2-memcache php7.2-memcached php7.2-mongodb php7.2-msgpack \
    php7.2-mysql php7.2-oauth php7.2-odbc php7.2-opcache php7.2-pgsql \
    php7.2-phpdbg php7.2-protobuf php7.2-pspell php7.2-raphf \
    php7.2-readline php7.2-recode php7.2-redis php7.2-rrd php7.2-snmp \
    php7.2-soap php7.2-solr php7.2-sqlite3 php7.2-ssh2 php7.2-sybase \
    php7.2-tidy php7.2-uploadprogress php7.2-uuid php7.2-xdebug \
    php7.2-xml php7.2-xmlrpc php7.2-xsl php7.2-yaml php7.2-zip \
    libapache2-mod-php7.2 2>/dev/null || echo "Some PHP 7.2 packages not available"

# PHP 7.3
echo "========================================"
echo "Installing PHP 7.3"
echo "========================================"
apt-get install -y \
    php7.3 php7.3-amqp php7.3-apcu php7.3-apcu-bc php7.3-ast \
    php7.3-bcmath php7.3-bz2 php7.3-cgi php7.3-cli php7.3-common \
    php7.3-curl php7.3-dba php7.3-decimal php7.3-ds php7.3-fpm \
    php7.3-gd php7.3-gearman php7.3-geoip php7.3-gmp php7.3-gnupg \
    php7.3-igbinary php7.3-imagick php7.3-inotify php7.3-intl \
    php7.3-json php7.3-ldap php7.3-libvirt-php php7.3-lz4 \
    php7.3-mbstring php7.3-mcrypt php7.3-memcache php7.3-memcached \
    php7.3-mongodb php7.3-msgpack php7.3-mysql php7.3-oauth \
    php7.3-opcache php7.3-pgsql php7.3-propro php7.3-protobuf \
    php7.3-pspell php7.3-radius php7.3-raphf php7.3-readline \
    php7.3-recode php7.3-redis php7.3-rrd php7.3-solr php7.3-sqlite3 \
    php7.3-ssh2 php7.3-tidy php7.3-uploadprogress php7.3-uuid \
    php7.3-xdebug php7.3-xml php7.3-xmlrpc php7.3-xsl php7.3-yaml \
    php7.3-zip 2>/dev/null || echo "Some PHP 7.3 packages not available"

# PHP 7.4
echo "========================================"
echo "Installing PHP 7.4"
echo "========================================"
apt-get install -y \
    php7.4 php7.4-amqp php7.4-apcu php7.4-apcu-bc php7.4-ast \
    php7.4-bcmath php7.4-bz2 php7.4-cgi php7.4-cli php7.4-common \
    php7.4-curl php7.4-dba php7.4-decimal php7.4-ds php7.4-enchant \
    php7.4-fpm php7.4-gd php7.4-geoip php7.4-gmp php7.4-gnupg \
    php7.4-grpc php7.4-igbinary php7.4-imagick php7.4-inotify \
    php7.4-interbase php7.4-intl php7.4-json php7.4-ldap \
    php7.4-libvirt-php php7.4-lz4 php7.4-mbstring php7.4-mcrypt \
    php7.4-memcache php7.4-memcached php7.4-mongodb php7.4-msgpack \
    php7.4-mysql php7.4-oauth php7.4-opcache php7.4-propro \
    php7.4-protobuf php7.4-pspell php7.4-raphf php7.4-readline \
    php7.4-redis php7.4-rrd php7.4-solr php7.4-sqlite3 php7.4-ssh2 \
    php7.4-uploadprogress php7.4-uuid php7.4-xdebug php7.4-xml \
    php7.4-yaml php7.4-zip 2>/dev/null || echo "Some PHP 7.4 packages not available"

# PHP 8.0
echo "========================================"
echo "Installing PHP 8.0"
echo "========================================"
apt-get install -y \
    php8.0 php8.0-amqp php8.0-apcu php8.0-ast php8.0-bcmath \
    php8.0-bz2 php8.0-cgi php8.0-cli php8.0-common php8.0-curl \
    php8.0-dba php8.0-decimal php8.0-enchant php8.0-fpm php8.0-gd \
    php8.0-gmp php8.0-gnupg php8.0-grpc php8.0-igbinary \
    php8.0-imagick php8.0-inotify php8.0-intl php8.0-ldap \
    php8.0-lz4 php8.0-mbstring php8.0-mcrypt php8.0-memcache \
    php8.0-memcached php8.0-mongodb php8.0-msgpack php8.0-mysql \
    php8.0-oauth php8.0-odbc php8.0-opcache php8.0-pgsql \
    php8.0-protobuf php8.0-pspell php8.0-raphf php8.0-readline \
    php8.0-redis php8.0-rrd php8.0-solr php8.0-sqlite3 php8.0-ssh2 \
    php8.0-uuid php8.0-xdebug php8.0-xml php8.0-xmlrpc php8.0-yaml \
    php8.0-zip 2>/dev/null || echo "Some PHP 8.0 packages not available"

# PHP 8.1
echo "========================================"
echo "Installing PHP 8.1"
echo "========================================"
apt-get install -y \
    php8.1 php8.1-amqp php8.1-apcu php8.1-ast php8.1-bcmath \
    php8.1-bz2 php8.1-cli php8.1-common php8.1-curl php8.1-fpm \
    php8.1-gd php8.1-igbinary php8.1-imagick php8.1-intl \
    php8.1-ldap php8.1-libvirt-php php8.1-mbstring php8.1-mcrypt \
    php8.1-memcache php8.1-memcached php8.1-msgpack php8.1-mysql \
    php8.1-opcache php8.1-phpdbg php8.1-pspell php8.1-raphf \
    php8.1-readline php8.1-redis php8.1-rrd php8.1-ssh2 php8.1-uuid \
    php8.1-xdebug php8.1-xml php8.1-zip 2>/dev/null || echo "Some PHP 8.1 packages not available"

# PHP 8.2
echo "========================================"
echo "Installing PHP 8.2"
echo "========================================"
apt-get install -y \
    php8.2 php8.2-amqp php8.2-apcu php8.2-ast php8.2-bcmath \
    php8.2-bz2 php8.2-cgi php8.2-cli php8.2-common php8.2-curl \
    php8.2-fpm php8.2-gd php8.2-grpc php8.2-http php8.2-igbinary \
    php8.2-imagick php8.2-imap php8.2-inotify php8.2-intl \
    php8.2-ldap php8.2-libvirt-php php8.2-lz4 php8.2-mbstring \
    php8.2-mcrypt php8.2-memcache php8.2-memcached php8.2-msgpack \
    php8.2-mysql php8.2-opcache php8.2-pgsql php8.2-phpdbg \
    php8.2-pspell php8.2-raphf php8.2-readline php8.2-redis \
    php8.2-rrd php8.2-snmp php8.2-ssh2 php8.2-uploadprogress \
    php8.2-uuid php8.2-xdebug php8.2-xml php8.2-zip php8.2-zstd \
    2>/dev/null || echo "Some PHP 8.2 packages not available"

# PHP 8.3
echo "========================================"
echo "Installing PHP 8.3"
echo "========================================"
apt-get install -y \
    php8.3 php8.3-ast php8.3-bcmath php8.3-bz2 php8.3-cli \
    php8.3-common php8.3-curl php8.3-fpm php8.3-gd php8.3-igbinary \
    php8.3-imagick php8.3-intl php8.3-ldap php8.3-mbstring \
    php8.3-memcache php8.3-msgpack php8.3-mysql php8.3-opcache \
    php8.3-phpdbg php8.3-pspell php8.3-readline php8.3-uuid \
    php8.3-xml php8.3-zip 2>/dev/null || echo "Some PHP 8.3 packages not available"

# Additional PHP tools and libraries
echo "========================================"
echo "Installing Additional PHP Tools"
echo "========================================"
apt-get install -y \
    php-apcu-bc \
    php-ast \
    php-bcmath \
    php-bz2 \
    php-curl \
    php-doctrine-lexer \
    php-email-validator \
    php-fpm \
    php-gd \
    php-geoip \
    php-igbinary \
    php-imagick \
    php-intl \
    php-ldap \
    php-libvirt-php \
    php-mbstring \
    php-mongo \
    php-msgpack \
    php-mysql \
    php-pspell \
    php-uuid \
    php-xml \
    php-zip 2>/dev/null || echo "Some additional PHP packages not available"

echo "========================================"
echo "Configuring PHP-FPM pools"
echo "========================================"

# Ensure PHP-FPM directories exist
for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
    mkdir -p /var/run/php
    if [ -f "/etc/php/${version}/fpm/php-fpm.conf" ]; then
        echo "Configuring PHP ${version} FPM..."
        # Set proper permissions
        sed -i 's/^listen.owner = .*/listen.owner = www-data/' /etc/php/${version}/fpm/pool.d/www.conf 2>/dev/null || true
        sed -i 's/^listen.group = .*/listen.group = www-data/' /etc/php/${version}/fpm/pool.d/www.conf 2>/dev/null || true
    fi
done

echo "========================================"
echo "Setting default PHP CLI version"
echo "========================================"

# Set PHP 7.4 as default CLI version
update-alternatives --set php /usr/bin/php7.4 2>/dev/null || \
    update-alternatives --set php /usr/bin/php8.0 2>/dev/null || \
    echo "Default PHP version not changed"

echo "========================================"
echo "PHP installation completed!"
echo "========================================"

# Display installed PHP versions
echo "Installed PHP versions:"
for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
    if [ -f "/usr/bin/php${version}" ]; then
        echo "  - PHP ${version}"
    fi
done