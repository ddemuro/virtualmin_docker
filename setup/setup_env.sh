#!/bin/bash
[[ -z $FUNCIMPORT ]] && source setup/functions_import.sh || echo "Function import missing or already imported"

DEBIAN_FRONTEND="noninteractive"

echo "Root DIR: $ROOTDIR | Config Dir: $SETUPDIR"

# Create environment
section_header "Creating environment"
python3 -m venv $ROOTDIR/.env

# Activate environment
message "Activating environment"
source $ROOTDIR/.env/bin/activate

message "Installing PIP libraries"
pip3 install --timeout 120 -r $SETUPDIR/requirements.txt
