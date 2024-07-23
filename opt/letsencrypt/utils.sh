#!/bin/bash

source /opt/letsencrypt/domlist.sh

readonly DEBUG=0
readonly LOG='/var/log/letsencrypt-d.log'
readonly AUTHHOOKPATH='/opt/letsencrypt/auth.sh'
readonly CLEANUPHOOKPATH='/opt/letsencrypt/cleanup.sh'
readonly CMDSPOOLER='/tmp/commandSpooler.run'
# Max lines in log
readonly MAXLINES=30000

# Reload bind
function reload_bind(){
    service bind9 reload
}

# Removes txt challenge to domain
function remove_from_zone(){
    FILENAME="/var/lib/bind/$1.hosts"
    FILENAME=${FILENAME/\.\./\.}
    echo "Removing TXT record!" >> $LOG
    sed -i "s/^_acme-challenge.$1.*$//g" $FILENAME
}

function rsync_to_servers(){
    for line in "${RSYNC_SERVERS[@]}"; do
        # Ensure servers are in sync
        rsync -avz --progress /opt/scripts/domain-certs/ root@$line:/opt/scripts/domain-certs/
    done
}

function rsync_to_binds(){
    for line in "${RSYNC_BIND[@]}"; do
        # Ensure servers are in sync
        rsync -avz --progress /var/lib/bind/ root@$line:/var/lib/bind/
    done
}

# Test domains with dig for all Auth DNS Servers
function dns_check_txt_challenge(){
    for server in "${DNS_P[@]}" ; do
        echo $server >> $LOG
        VALUE=`dig TXT +noadditional +noquestion +nocomments +nocmd +nostats +short "_acme-challenge.$CERTBOT_DOMAIN." @$server`
        echo $VALUE >> $LOG
        if [ "$VALUE" != "\"$1\"" ] ; then
            echo "Didn't validate, $VALUE is not equal to $1" >> $LOG
            rsync_to_binds
            sleep 5
            RES=-1
            return 1
        fi
        RES=0
    done
    return 0
}

# Create taskSpooler queue to reload apache / nginx
function reload_services_tskspool(){
    # Reload apache in SEC01
    CMDVAR=""
    CMDVAR2=""
    for sym in "${SYMLINKS[@]}"; do
        CMDVAR="$CMDVAR ln -sn $sym\n"
    done
    # Gen domains
    for line in "${DNS_TO_VALIDATE[@]}"; do
        line=`echo $line | sed 's/\*\.//g'`
        CMDVAR2="$CMDVAR2 cp /opt/scripts/domain-certs/$line/ssl.* /home/$line/\n"
    done

    echo "Telling servers to check symlinks with: $CMDVAR and $CMDVAR2" >> $LOG
    ssh root@10.3.0.49 "service nginx reload"
    ssh root@10.3.3.49 "service nginx reload"
    ssh root@lsyncd-vmin.la.takelan.com "service nginx reload"
    ssh root@10.3.3.45 "service nginx reload"
    service apache2 reload
    service postfix restart
    service dovecot restart
}

# Copy certs to shared location
function copy_certs(){
    # Gen domains
    for line in "${DNS_TO_VALIDATE[@]}"; do
        line=`echo $line | sed 's/\*\.//g'`
        LOCATION="/opt/scripts/domain-certs/$line"
        mkdir -p $LOCATION
        # Copy the certs
        cp /etc/letsencrypt/live/$line/fullchain.pem $LOCATION/ssl.cert
        cp /etc/letsencrypt/live/$line/privkey.pem $LOCATION/ssl.key
        # Copy to home
        cp $LOCATION/ssl.cert /home/$line/ssl.cert
        cp $LOCATION/ssl.key /home/$line/ssl.key
    done
    service apache2 reload 
    echo "Done copying to folder"
}

# Check symlinks
function create_symlinks(){
    for sym in "${SYMLINKS[@]}"; do
        echo "Checking symlink for: $sym" >> $LOG
        p1=`echo $sym | cut -d' ' -f1`
        p2=`echo $sym | cut -d' ' -f2`
        echo "ln -s $p1 $p2" >> $LOG
        ln -sn "$p1" "$p2"
    done
}

# Adds txt challenge to domain
function add_to_zone(){
    FILENAME="/var/lib/bind/$1.hosts"
    FILENAME=${FILENAME/\.\./\.}
    TXT="_acme-challenge.$1.    5    IN    TXT    \"$2\""
    echo "$FILENAME $1 $TXT" >> $LOG
    if grep -Fqx "_acme-challenge.$1" $FILENAME; then
        sed -i "s/^_acme-challenge.$1.*$/$TXT/g" $FILENAME
    else
        echo "$TXT" >> $FILENAME
    fi
}

###Function to clear the log
function clearLog() {
  echo 'Log cleared' > $LOG
  echo 'Script will run ' $1 ' times then will clear itself'>> $LOG
}

## We check if the logfile exists, otherwise we create it
if [ ! -f $LOG ]; then
	touch $LOG
fi

##CLEAR THE LOG IF LINES > MAXLINES
loglines=`wc -l < $LOG`
if [ $loglines -eq $MAXLINES ]; then
	clearlog
fi
