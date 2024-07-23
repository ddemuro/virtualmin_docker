#!/bin/bash

BACKUP_FLDR='/var/dovecot-backup/'
LOGFILENAME='dovecotindex-fixer.log'
DATE=`date`
SOURCE='/home/'

echo "==================================================== Start: $DATE ==============================================" >> /var/log/$LOGFILENAME
mkdir -p $BACKUP_FLDR

# Find files to clean
find $SOURCE -type f \( -name "dovecot.index" -o -name "dovecot.index.cache*" -o -name "dovecot.index.thread*" -o -name ".nfs*" \) >> /var/log/$LOGFILENAME
# Clean them
find $SOURCE -type f \( -name "dovecot.index" -o -name "dovecot.index.cache*" -o -name "dovecot.index.thread*" -o -name ".nfs*" \) -exec mv --backup=numbered {} $BACKUP_FLDR \;

service dovecot restart >> /var/log/$LOGFILENAME

echo "==================================================== Finished: $DATE ==============================================" >> /var/log/$LOGFILENAME

