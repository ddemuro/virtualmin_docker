#!/usr/bin/env bash

# Install inotify-tools if not already installed
if ! command -v inotifywait &> /dev/null; then
    apt-get install -qq -y inotify-tools &>/dev/null
fi

# Reload Apache
while true; do
    inotifywait -r /etc/apache2 &>/dev/null
    sleep 5
    systemctl reload apache2
    echo "Apache2 reloaded due to file change." &>>/var/log/lsyncd.log
done
