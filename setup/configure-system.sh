#!/bin/bash
# System Configuration Script for Virtualmin Docker
set -e

echo "========================================"
echo "Configuring System Environment"
echo "========================================"

# Create necessary directories
echo "Creating required directories..."
mkdir -p /var/run/sshd
mkdir -p /var/run/apache2
mkdir -p /var/run/php
mkdir -p /var/run/dovecot
mkdir -p /var/run/mysqld
mkdir -p /var/log/apache2
mkdir -p /var/log/mysql
mkdir -p /var/log/mail
mkdir -p /var/log/virtualmin
mkdir -p /var/log/supervisor
mkdir -p /var/run/supervisor
mkdir -p /data/backups
mkdir -p /data/updates
mkdir -p /var/cache/bind
mkdir -p /var/lib/mysql
mkdir -p /var/vmail
mkdir -p /var/mail

# Set proper permissions
echo "Setting directory permissions..."
chmod 755 /var/run/sshd
chown mysql:mysql /var/run/mysqld 2>/dev/null || true
chown mysql:mysql /var/lib/mysql 2>/dev/null || true
chown bind:bind /var/cache/bind 2>/dev/null || true
chown -R www-data:www-data /var/log/apache2 2>/dev/null || true
chmod 755 /data/backups
chmod 755 /data/updates

echo "========================================"
echo "Configuring Locales"
echo "========================================"

# Configure locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

echo "========================================"
echo "Configuring Timezone"
echo "========================================"

# Set timezone (can be overridden by environment variable)
if [ -n "$TZ" ]; then
    echo "Setting timezone to $TZ"
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
else
    echo "Using default timezone (UTC)"
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    echo "UTC" > /etc/timezone
fi

echo "========================================"
echo "Configuring SSH"
echo "========================================"

# Configure SSH
sed -i 's/#PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "UseDNS no" >> /etc/ssh/sshd_config

# Generate SSH host keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

echo "========================================"
echo "Configuring Apache"
echo "========================================"

# Enable Apache modules
a2enmod rewrite ssl headers expires deflate proxy proxy_fcgi setenvif || true

# Configure Apache for PHP-FPM
for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
    if [ -f "/etc/php/${version}/fpm/php-fpm.conf" ]; then
        cat > /etc/apache2/conf-available/php${version}-fpm.conf <<EOF
<FilesMatch \.php$>
    SetHandler "proxy:unix:/var/run/php/php${version}-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF
    fi
done

# Set ServerName to avoid warning
echo "ServerName localhost" >> /etc/apache2/apache2.conf

echo "========================================"
echo "Configuring Postfix"
echo "========================================"

# Basic Postfix configuration
postconf -e "inet_interfaces = all"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 172.16.0.0/12"
postconf -e "home_mailbox = Maildir/"
postconf -e "smtpd_banner = \$myhostname ESMTP"

echo "========================================"
echo "Configuring Dovecot"
echo "========================================"

# Basic Dovecot configuration
if [ -f /etc/dovecot/dovecot.conf ]; then
    sed -i 's/#listen = .*/listen = */' /etc/dovecot/dovecot.conf || true
    echo "mail_location = maildir:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf || true
fi

echo "========================================"
echo "Configuring BIND/Named"
echo "========================================"

# Configure BIND
if [ -f /etc/bind/named.conf.options ]; then
    sed -i 's/dnssec-validation auto;/dnssec-validation no;/' /etc/bind/named.conf.options || true
    echo 'include "/etc/bind/virtualmin.conf";' >> /etc/bind/named.conf.local || true
    touch /etc/bind/virtualmin.conf
    chown bind:bind /etc/bind/virtualmin.conf
fi

echo "========================================"
echo "Configuring MySQL/MariaDB Client"
echo "========================================"

# Configure MySQL client
cat > /etc/mysql/conf.d/client.cnf <<EOF
[client]
host = mysql
port = 3306
EOF

echo "========================================"
echo "Configuring Fail2ban"
echo "========================================"

# Basic fail2ban configuration
if [ -f /etc/fail2ban/jail.conf ]; then
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sed -i 's/backend = auto/backend = systemd/' /etc/fail2ban/jail.local || true
fi

echo "========================================"
echo "Configuring ClamAV"
echo "========================================"

# Configure ClamAV
if [ -f /etc/clamav/clamd.conf ]; then
    sed -i 's/^LocalSocket .*/LocalSocket \/var\/run\/clamav\/clamd.ctl/' /etc/clamav/clamd.conf || true
    sed -i 's/^#TCPSocket/TCPSocket/' /etc/clamav/clamd.conf || true
    mkdir -p /var/run/clamav
    chown clamav:clamav /var/run/clamav
fi

if [ -f /etc/clamav/freshclam.conf ]; then
    sed -i 's/^Checks .*/Checks 2/' /etc/clamav/freshclam.conf || true
fi

echo "========================================"
echo "Setting up Log Rotation"
echo "========================================"

# Configure logrotate for Virtualmin logs
cat > /etc/logrotate.d/virtualmin <<EOF
/var/log/virtualmin/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        systemctl reload apache2 > /dev/null 2>&1 || true
    endscript
}
EOF

echo "========================================"
echo "Creating Default Index Page"
echo "========================================"

# Create a default index page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Virtualmin Server</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; display: inline-block; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Virtualmin Server</h1>
    <div class="info">
        <p>This server is managed by Virtualmin</p>
        <p><a href="https://$(hostname -I | cut -d' ' -f1):10000">Access Virtualmin Control Panel</a></p>
        <p>Server Status: Active</p>
    </div>
</body>
</html>
EOF

echo "========================================"
echo "Configuring Supervisor"
echo "========================================"

# Ensure supervisor config directory exists
mkdir -p /etc/supervisor/conf.d

# Configure supervisor main config if needed
if [ -f /etc/supervisor/supervisord.conf ]; then
    sed -i 's/^chmod=0700/chmod=0766/' /etc/supervisor/supervisord.conf || true
fi

echo "========================================"
echo "Setting System Limits"
echo "========================================"

# Increase system limits
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

# Increase sysctl limits
cat >> /etc/sysctl.conf <<EOF
fs.file-max = 65536
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.ip_local_port_range = 10000 65000
EOF

echo "========================================"
echo "Creating Helper Scripts"
echo "========================================"

# Create service status check script
cat > /usr/local/bin/check-services <<'EOF'
#!/bin/bash
echo "Checking service status..."
services=("apache2" "mysql" "postfix" "dovecot" "sshd" "named" "webmin")
for service in "${services[@]}"; do
    if pgrep -x "$service" > /dev/null; then
        echo "✓ $service is running"
    else
        echo "✗ $service is not running"
    fi
done
EOF
chmod +x /usr/local/bin/check-services

# Create quick restart script
cat > /usr/local/bin/restart-all <<'EOF'
#!/bin/bash
echo "Restarting all services..."
supervisorctl restart all 2>/dev/null || {
    service apache2 restart
    service mysql restart
    service postfix restart
    service dovecot restart
    service bind9 restart
    service ssh restart
    service webmin restart
    for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
        service php${version}-fpm restart 2>/dev/null || true
    done
}
echo "All services restarted"
EOF
chmod +x /usr/local/bin/restart-all

echo "========================================"
echo "Configuring Automated Backups"
echo "========================================"

# Configure backup cron
if [ -f /etc/cron.d/virtualmin-backup ]; then
    # Replace placeholders with actual passwords from environment
    sed -i "s/MYSQL_ROOT_PASSWORD_PLACEHOLDER/${MYSQL_ROOT_PASSWORD}/g" /etc/cron.d/virtualmin-backup
    sed -i "s/LDAP_ADMIN_PASSWORD_PLACEHOLDER/${LDAP_ADMIN_PASSWORD}/g" /etc/cron.d/virtualmin-backup

    # Ensure cron can read the file
    chmod 644 /etc/cron.d/virtualmin-backup

    echo "Backup automation configured"
fi

# Create initial backup directories
mkdir -p /backups/{daily,weekly,monthly,quick,mysql}
chown -R root:root /backups
chmod -R 755 /backups

# Create backup log file
touch /backups/backup.log
chmod 644 /backups/backup.log

echo "========================================"
echo "Final System Cleanup"
echo "========================================"

# Clean apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Clear temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "========================================"
echo "System configuration completed!"
echo "========================================"