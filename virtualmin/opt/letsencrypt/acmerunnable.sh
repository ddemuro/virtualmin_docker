#!/bin/bash

source /opt/letsencrypt/utils.sh

apt-get install -qq python-certbot-apache -t stretch-backports

# Test domains with dig for all Auth DNS Servers
function dns_check_txt_challenge(){
    for server in "${DNS_TO_VALIDATE[@]}"; do
        echo "Running certbot for $server" >> $LOG
        if [ $DEBUG -eq 1 ]; then
            echo "Dry run running..."
            certbot certonly --manual --dry-run --preferred-chain "ISRG Root X1" -n --agree-tos --preferred-challenges=dns --manual-auth-hook $AUTHHOOKPATH --manual-cleanup-hook $CLEANUPHOOKPATH -d "$server" >> $LOG
        else
            echo "Running in real mode"
            certbot certonly --manual --preferred-chain "ISRG Root X1" --preferred-challenges=dns -n --agree-tos --manual-auth-hook $AUTHHOOKPATH --manual-cleanup-hook $CLEANUPHOOKPATH -d "$server" >> $LOG
        fi
    done
}

# Run certbot!
dns_check_txt_challenge

# Check symlinks
create_symlinks

# Copy certificates to shared location
copy_certs

# Send files to the servers
rsync_to_servers

# Reload services
reload_services_tskspool

# Cleanup obsolete certs
find /etc/letsencrypt/csr/ -type f -mtime +120 -exec rm {} \;
find /etc/letsencrypt/keys/ -type f -mtime +120 -exec rm {} \;
find /etc/letsencrypt/archive/ -type f -mtime +120 -exec rm {} \;

echo "Done. $DEBUG" >> $LOG
