#!/bin/bash

service apache2 start
service mysql start
service dovecot start

#PHP
declare -a arr=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3")
## now loop through the above array
for i in "${arr[@]}"; do
    echo "$i"
    service "php$i-fpm" start
done

declare -a services=("apache2" "slapd" "saslauthd" "opendmarc" "mysql" "dovecot" "postfix" "dovecot" "netdata" "proftpd" "virtualmin" "webmin")

for i in "${services[@]}"; do
       echo "Stopping $i"
       service $i start
done

