#!/bin/bash
# Service startup script for consolidated Virtualmin container

set -e

echo "========================================"
echo "Starting All Services in Virtualmin Container"
echo "========================================"

# Note: MySQL runs in a separate container, but SLAPD is installed locally

# Start SSH daemon
echo "Starting SSH service..."
service ssh start || systemctl start ssh || /usr/sbin/sshd -D &

# Start OpenLDAP (SLAPD)
echo "Starting OpenLDAP service..."
service slapd start || systemctl start slapd || /usr/sbin/slapd -h "ldap:/// ldaps:///" -g openldap -u openldap -F /etc/ldap/slapd.d &

# Start Apache
echo "Starting Apache service..."
service apache2 start || systemctl start apache2 || apachectl start

# Start Postfix
echo "Starting Postfix service..."
service postfix start || systemctl start postfix || postfix start

# Start Dovecot
echo "Starting Dovecot service..."
service dovecot start || systemctl start dovecot || dovecot

# Start Bind9
echo "Starting Bind9 DNS service..."
service bind9 start || systemctl start bind9 || named -g &

# Start ClamAV
echo "Starting ClamAV services..."
service clamav-freshclam start || systemctl start clamav-freshclam || freshclam -d
service clamav-daemon start || systemctl start clamav-daemon || clamd

# Start Webmin/Virtualmin
echo "Starting Webmin/Virtualmin..."
service webmin start || systemctl start webmin || /etc/webmin/start

# Start cron
echo "Starting cron service..."
service cron start || systemctl start cron || cron

# Start fail2ban
echo "Starting fail2ban..."
service fail2ban start || systemctl start fail2ban || fail2ban-client start

# Start all PHP-FPM versions
echo "Starting PHP-FPM services..."
for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do
    if [ -f "/etc/init.d/php${version}-fpm" ]; then
        echo "Starting PHP ${version} FPM..."
        service php${version}-fpm start || systemctl start php${version}-fpm || true
    fi
done

echo "========================================"
echo "All services started successfully"
echo "========================================"

# Keep container running
echo "Container ready. Services are running..."
tail -f /dev/null