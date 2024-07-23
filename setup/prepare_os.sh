#!/bin/bash

[[ -z $FUNCIMPORT ]] && source setup/functions_import.sh || echo "Function import missing or already imported"

DEBIAN_FRONTEND="noninteractive"

echo "Root DIR: $ROOTDIR | Config Dir: $SETUPDIR"

section_header "Updating apt repositories"
update_apt

section_header "Installing system dependencies"
requirements_debian=$SETUPDIR/debian_requirements.txt
if [ $DEBUG -eq 0 ]; then cat $requirements_debian; fi 
install_requirements ${requirements_debian}

# Cleanup
section_header "Cleaning up"
apt-get autoremove -y && apt-get clean

section_header "Creating main user"
# Create new user
useradd -m takelan; echo "takelan:__CHANGE__ME" | chpasswd

section_header "Preparing sudoers file"
# Copy sudoers
cp $SETUPDIR/sudoers /etc/sudoers

section_header "Prepping folders and permissions"
# Allow anyone to touch anything in here.
chmod -R 777 /srv
mkdir -p /home/takelan/.cache/
chmod -R 777 /home/takelan/.cache/
