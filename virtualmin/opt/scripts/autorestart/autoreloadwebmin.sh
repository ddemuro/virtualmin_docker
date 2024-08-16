#!/usr/bin/env bash

# Install inotify-tools if not already installed
if ! command -v inotifywait &> /dev/null; then
    apt-get install -qq -y inotify-tools &>/dev/null
fi

# Reload Webmin
while true; do
    inotifywait -r -e move /etc/webmin/virtual-server &>/dev/null
    sleep 5
    systemctl reload webmin
    echo "Webmin reloaded due to file change." &>>/var/log/lsyncd.log
done
exit 0
