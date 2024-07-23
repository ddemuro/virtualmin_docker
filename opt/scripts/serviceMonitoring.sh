#!/bin/bash
# Check for service status and eventually do something about it.
# Bruno Bense

################################################################################
# README (OR "HOW TO USE THIS SCRIPT") !! THIS BIT IS IMPORTANT !!             #
################################################################################
# 
# This script just checks for the status of each one of the services specified
# on the 'services' constant below.
#
# It depends mostly on the exit codes of each init script, and we asume that
# every single init script out there follows the defacto standard for init
# scripts exit codes. For more information, check out the following link:
#
# https://fedoraproject.org/wiki/FCNewInit/Initscripts#Init_Script_Actions
#
################################################################################
# SCRIPT CONFIGURATION                                                         #
################################################################################

# Enter the services you wish to monitor separated by spaces
readonly services='ssh bind9 mysql apache2'

# Sleep every... xyz
SLEEP=180

################################################################################
# SCRIPT FUNCTIONS                                                             #
################################################################################

function startService() {
	# USAGE: startService [service-name]
	# DESCRIPTION: Attempts to start a service.
	
	echo "Starting $1"
	messages=`service $1 start`
	
	if [ $? -eq "0" ]
	then
		# Service failed to start
		echo $messages
		return 1
	else
		# Service started successfully
		echo "$1 started succesfully"
		return 0
	fi		
}

function checkService() {

	# USAGE: checkService [service-name]
	# DESCRIPTION: Checks on the status of the specified service.
	
	service $1 status > /dev/null
	serviceStatus="$?"
	
	case $serviceStatus in
		'0')
			# Service is running 
			#echo "$1 is running."
			:
			;;
		'1')
			# Service is dead and /var/run pid file exists 
			echo "$1 is not running: Service is dead and /var/run pid file exists."
			startService $1
			;;
		'2')
			# Service is dead and /var/lock lock file exists 
			echo "$1 is not running: Service is dead and /var/lock lock file exists."
			startService $1
			;;			
		'3')
			# Service is not running
			echo "$1 is stopped."
			startService $1
			;;
		'4')
			# Service status is unknown
			echo "$1 status is unknown."
			startService $1
			;;			
		*)
			echo "Could not determine service status."
			;;
	esac
}

################################################################################
# SCRIPT EXCECUTION STARTS HERE                                                #
################################################################################

#for service in `echo $services`
#do
#	checkService $service
#done

while true; do
    for service in `echo $services`
    do
        checkService $service
    done
    sleep $SLEEP
    /opt/scripts/checkServiceDate.sh >> /dev/null 
done
