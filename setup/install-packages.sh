#!/bin/bash
# Package installation script for Virtualmin Docker
set -e

echo "========================================"
echo "Installing Virtualmin Core Packages"
echo "========================================"

# Update package lists
apt-get update

# Install core Virtualmin package
apt-get install -y virtualmin-core

echo "========================================"
echo "Installing Web Server Packages"
echo "========================================"

# Apache and related packages
apt-get install -y \
    apache2 \
    apache2-bin \
    apache2-data \
    apache2-doc \
    apache2-suexec-custom \
    apache2-utils \
    libapache2-mod-auth-plain \
    libapache2-mod-authn-yolo \
    libapache2-mod-bw \
    libapache2-mod-fcgid \
    libapache2-mod-geoip \
    libapache2-mod-mapcache \
    libapache2-mod-python \
    libapache2-mod-removeip \
    libapache2-mod-rpaf \
    libapache2-mod-upload-progress \
    libapache2-mod-uwsgi \
    libapache2-mod-webauth \
    libapache2-mod-xsendfile

echo "========================================"
echo "Installing Mail Server Packages"
echo "========================================"

# Mail services
apt-get install -y \
    postfix \
    postfix-ldap \
    postfix-pcre \
    postfix-sqlite \
    dovecot-core \
    dovecot-imapd \
    dovecot-ldap \
    dovecot-pop3d \
    procmail \
    procmail-wrapper

echo "========================================"
echo "Installing DNS and Network Services"
echo "========================================"

# DNS and network packages
apt-get install -y \
    bind9 \
    bind9-dnsutils \
    bind9-host \
    bind9-utils \
    bind9utils \
    iptables \
    firewalld \
    fail2ban

echo "========================================"
echo "Installing Security Packages"
echo "========================================"

# Security and SSL
apt-get install -y \
    certbot \
    clamav \
    clamav-base \
    clamav-daemon \
    clamav-docs \
    clamav-freshclam \
    clamav-testfiles \
    clamdscan \
    jailkit \
    openssl

echo "========================================"
echo "Installing Database Tools"
echo "========================================"

# Database related (client tools only, server is in separate container)
apt-get install -y \
    default-mysql-client \
    libmysqlclient-dev

echo "========================================"
echo "Installing Development Tools"
echo "========================================"

# Development and build tools
apt-get install -y \
    git \
    git-man \
    automake \
    autopoint \
    libtool \
    libtool-bin \
    m4 \
    make \
    gcc \
    g++ \
    re2c \
    fakeroot

echo "========================================"
echo "Installing System Utilities"
echo "========================================"

# System utilities
apt-get install -y \
    cron \
    curl \
    wget \
    rsync \
    unzip \
    zip \
    p7zip \
    bzip2 \
    pbzip2 \
    pigz \
    lzop \
    gzip \
    tar \
    sed \
    grep \
    awk \
    findutils \
    coreutils \
    diffutils \
    patch \
    less \
    nano \
    vim \
    htop \
    screen \
    tmux \
    byobu \
    ncal \
    tree \
    mtr \
    traceroute \
    iputils-ping \
    dnsutils \
    net-tools \
    telnet \
    lynx \
    lynx-common \
    mutt \
    pastebinit \
    speedtest-cli \
    inotify-tools \
    logrotate \
    nscd \
    openssh-client \
    openssh-server \
    openssh-sftp-server

echo "========================================"
echo "Installing Monitoring Tools"
echo "========================================"

# Monitoring and logging
apt-get install -y \
    filebeat || echo "Filebeat not available, skipping..."

echo "========================================"
echo "Installing Additional Services"
echo "========================================"

# Additional services
apt-get install -y \
    csync2 \
    rpcbind \
    preload \
    aria2 \
    javascript-common

echo "========================================"
echo "Installing Perl Modules"
echo "========================================"

# Essential Perl modules for Webmin/Virtualmin
apt-get install -y \
    perl \
    perl-base \
    libarchive-cpio-perl \
    libarchive-zip-perl \
    libmime-lite-perl \
    libmime-types-perl \
    libmodule-find-perl \
    libmodule-implementation-perl \
    libmodule-runtime-perl \
    libmodule-scandeps-perl \
    libmoo-perl \
    libmro-compat-perl \
    libnamespace-autoclean-perl \
    libnamespace-clean-perl \
    libnet-cidr-perl \
    libnet-dbus-perl \
    libnet-dns-perl \
    libnet-dns-sec-perl \
    libnet-http-perl \
    libnet-ip-perl \
    libnet-ldap-perl \
    libnet-libidn-perl \
    libnet-rblclient-perl \
    libnet-server-perl \
    libnet-smtp-ssl-perl \
    libnet-ssleay-perl \
    libnet-xwhois-perl \
    libnetaddr-ip-perl \
    libpackage-stash-perl \
    libpackage-stash-xs-perl \
    libpadwalker-perl \
    libparams-classify-perl \
    libparams-util-perl \
    libparams-validationcompiler-perl \
    libparse-syslog-perl \
    libperl4-corelibs-perl \
    libproc-processtable-perl \
    libreadonly-perl \
    libref-util-perl \
    libref-util-xs-perl \
    librole-tiny-perl \
    libsocket6-perl \
    libsort-naturally-perl \
    libspecio-perl \
    libstrictures-perl \
    libsub-exporter-perl \
    libsub-exporter-progressive-perl \
    libsub-identify-perl \
    libsub-install-perl \
    libsub-name-perl \
    libsub-override-perl \
    libsub-quote-perl \
    libswitch-perl \
    libsys-hostname-long-perl \
    libterm-readkey-perl \
    libterm-spinner-color-perl \
    libtext-charwidth-perl \
    libtext-iconv-perl \
    libtext-wrapi18n-perl \
    libtie-ixhash-perl \
    libtimedate-perl \
    libtry-tiny-perl \
    libtype-tiny-perl \
    libtype-tiny-xs-perl \
    libtypes-serialiser-perl \
    liburi-perl \
    libwww-perl \
    libwww-robotrules-perl \
    libxml-twig-perl \
    libxml-xpathengine-perl \
    libxstring-perl

echo "========================================"
echo "Installing Additional Libraries"
echo "========================================"

# Additional libraries
apt-get install -y \
    libsasl2-dev \
    libmcrypt4 \
    libmemcached-tools \
    libspf2-2 \
    libopendbx1-sqlite3 \
    libarmadillo10 \
    enchant-2 \
    geoip-database \
    ispell \
    odbcinst \
    mime-support \
    locales \
    uuid

echo "========================================"
echo "Cleaning up package cache"
echo "========================================"

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "========================================"
echo "Package installation completed!"
echo "========================================"