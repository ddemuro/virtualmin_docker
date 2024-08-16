#!/bin/bash

# Disable clamav mainly for lax
systemctl stop clamav-freshclam.service clamav-daemon.service; systemctl disable clamav-freshclam.service clamav-daemon.service

service $1 slapd

#PHP
declare -a arr=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3")
## now loop through the above array
for i in "${arr[@]}"; do
    echo "$i"
    service "php$i-fpm" $1
done

declare -a services=("apache2" "saslauthd" "opendmarc" "mysql" "dovecot" "postfix" "dovecot" "netdata" "proftpd" "virtualmin" "webmin" "usermin")

for i in "${services[@]}"; do
       echo "Stopping $i"
       service $i $1
done

