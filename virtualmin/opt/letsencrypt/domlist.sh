#!/bin/bash
# Domains
DNS_TO_VALIDATE=(

)

# Auth nameservers
DNS_P=(
    'ns1.takelan.com'
)

# Symlinks
SYMLINKS=(
    '/home/tkln /home/tkln.dev'
)

# Sync to different bind servers
RSYNC_BIND=(
    '10.3.0.45'
)

# To sync certificates to all the servers
RSYNC_SERVERS=(
    '10.3.0.49'
)
