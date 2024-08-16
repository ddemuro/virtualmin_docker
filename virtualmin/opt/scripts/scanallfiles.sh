#!/bin/bash

SUBJECT="Reporting on domain - "
EMAIL="mail@derekdemuro.com"
FROM="phpscanner@mi01.takelan.com"
DELREP="/tmp/scanrepdel/"

mkdir -p $DELREP

for domain in $(find -L /home -mindepth 1 -maxdepth 1 -type d) ; do
    echo $domain;
    for subdomain in $(find -L $domain/domains/ -mindepth 1 -maxdepth 1 -type d) ; do
        #echo $subdomain;
        php7.4 /home/PHP-Antimalware-Scanner/src/index.php --report-format txt --path-backups /mnt/backup/phpfiles/ --no-color $subdomain/public_html --report --path-report $DELREP | mail -a FROM:$FROM -s "$SUBJECT - $subdomain" $EMAIL
    done
    php7.4 /home/PHP-Antimalware-Scanner/src/index.php --report-format txt --path-backups /mnt/backup/phpfiles/ --no-color $domain/public_html --report --path-report $DELREP |  mail -a FROM:$FROM -s "$SUBJECT - $domain" $EMAIL
done

# Delete files older than 7 days
find $DELREP -type f -mtime +7 -name '*' -execdir rm -- '{}' \;

echo "Done"
