#!/bin/bash

mkdir -p /var/run/lsyncd/ /var/lsyncdbackup/
#MINIO_SECRET_KEY=6375sodeep MINIO_ACCESS_KEY=minio /opt/minio server /mnt/docker-data/minio &disown
bash /opt/scripts/lsyncedMonitor.sh &disown
bash /opt/scripts/lsyncedMonitor-homes.sh &disown
bash /opt/scripts/cronjob.sh &disown
bash /opt/scripts/serviceMonitoring.sh &disown
#bash /opt/scripts/autorestart/autoreloadwebmin.sh &disown
#bash /opt/scripts/autorestart/autoreloadapache.sh &disown
bash /opt/scripts/autorestart/autoreloadbind.sh &disown
bash /opt/scripts/autorestart/autoreloaddovecot.sh &disown
exit 0
