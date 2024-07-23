#!/bin/bash

[[ -z $FUNCIMPORT ]] && source setup/functions_import.sh || echo "Function import missing or already imported"

PYTHONUNBUFFERED=TRUE


# Normal start
function start_normal() {
    message "Starting Virtualmin."
    
}

# Start debug mode, lock only
function debug() {
    cd $ROOTDIR
    # We might need this as default
    message "Starting virtualmin while monitoring logs."
}

case "${OPERATION}" in
    lock)
        tail -f /dev/null
        ;;
    start)
        start_normal
        ;;
    debug)
        debug
        ;;
    *)
        message "Don't forget you can call container $ OPERATION=start GID=$(id -g) UID=$(id -u) docker-compose up \
         tkvmin or $ OPERATION=start GID=$(id -g) UID=$(id -u) docker-compose -d up tkvmin to run once"
        start_normal
        ;;
esac
