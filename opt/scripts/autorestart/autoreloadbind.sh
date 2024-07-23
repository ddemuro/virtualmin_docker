#!/usr/bin/env bash

# Install inotify-tools if not already installed
if ! command -v inotifywait &> /dev/null; then
    apt-get install -qq -y inotify-tools &>/dev/null
fi

monitor_bind() {
    inotifywait -r /var/lib/bind &>/dev/null
    while true; do
        inotifywait -r -e move /var/lib/bind &>/dev/null
        sleep 5
        systemctl reload bind9
        echo "Bind9 reloaded due to file change." >> /var/log/lsyncd.log
    done
}

main_loop() {
    while true; do
        monitor_bind || { echo "Script crashed. Restarting..." >&2; sleep 1; }
    done
}

main_loop
