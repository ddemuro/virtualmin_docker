#!/bin/bash

# To import copy and paste in script
#[[ -z $FUNCIMPORT ]] && . functions_import.sh || echo "Function import missing or already imported"

# Set directory (Needed for deploy)
#SETUPDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#if [ "$SETUPDIR" == "/tmp" ]; then
SETUPDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ROOTDIR=`dirname $SETUPDIR`
#fi

### Colorized output #######
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# For pretty output
function section_header() {
    echo -e "${GREEN}=========================================================================================${NC}"
    echo -e "${GREEN}= $(date -u) SECTION: $1 ${NC}"
    echo -e "${GREEN}=========================================================================================${NC}"
}

function message() {
    echo -e "${GREEN} > $(date -u) $1 ${NC}"
}

# For ERROR notifications
function error_header() {
    echo -e "${RED}/****************************************************************************************${NC}"
    echo -e "${RED}/ $(date -u) ERROR: $1 ${NC}"
    echo -e "${RED}/****************************************************************************************${NC}"
}

# Start ubuntu service
function start_service() {
    service $1 start
    if [ $? -eq 0 ]; then
        message "${GREEN} Service $1 started"
    else
        error_header "${RED} Service $1 failed to start."
    fi
}

# Stop a service with validation
function stop_service() {
    service $1 stop
    if [ $? -eq 0 ]; then
        message "${GREEN} Service $1 stopped"
    else
        error_header "${RED} Service $1 failed to stop."
    fi
}

# Lock so docker will continue running.
function lock_for_docker_ui() {
    tail -f /dev/null
}

# Update APT sources.
function update_apt() {
    section_header "Updating apt."
    apt-get -y update
    if [ $? -eq 0 ]; then
        message "APT Sources updated successfully."
    else
        error_header "APT Sources update failed."
    fi
}

# Update system
function update_system() {
    section_header "Updating system."
    if [ $DEBUG -eq 0 ]; then
        apt-get -y upgrade
    else
        apt-get -y upgrade &>> /dev/null
    fi
    if [ $? -eq 0 ]; then
        message "System updated successfully."
    else
        error_header "System update failed."
    fi
}

# Check if string contains
function str_contains() {
    local STR=$1
    local SUB=$2
    if [[ "$STR" == *"$SUB"* ]]; then
        return 0
    fi
    return 1
}

# Function to install a list of packages from a requirements file
function install_requirements() {
    local requirements_file="$1"

    # Check if the requirements file exists
    if [[ ! -f "$requirements_file" ]]; then
        error_header "Requirements file not found: $requirements_file"
        return 1
    fi

    # Set IFS to handle lines properly and iterate over each package
    local OLDIFS="$IFS"
    IFS=$'\n'
    while read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" == \#* ]] && continue

        message "Installing package: $package"
        if ! install_package_if_not_installed "$package"; then
            error_header "Failed to install package: $package"
        fi
    done < "$requirements_file"
    IFS="$OLDIFS"
}

# Example functions for error and message handling
function install_package_if_not_installed() {
    local package=$1
    if [ $DEBUG -eq 0 ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $package
        return $?
    fi
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $package &>> /dev/null
    return $?
}

# Function to download a file
function download_file() {
    local download_link="$1"
    local output_location="$2"

    # Ensure curl is installed
    install_package_if_not_installed "curl"

    # Use curl to download the file with error checking
    if curl -k -s --fail "$download_link" -o "$output_location"; then
        message "Package downloaded successfully: $download_link"
        return 0
    else
        error_header "Failed to download package: $download_link. Please check your connection."
        return 1
    fi
}

# NOOP
function do_nothing(){
    return 0
}

# 
