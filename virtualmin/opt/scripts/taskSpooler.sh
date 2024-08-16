#!/bin/bash
# Runs as root commands in a file /spoolerstyle
# Derek Demuro - TakeLAN

################################################################################
# README (OR "HOW TO USE THIS SCRIPT") !! THIS BIT IS IMPORTANT !!             #
################################################################################
# 
# This script runs commands in a file as root, and after the execution completed
# we remove it from the file and move on.
# # TaskSpooler
# 0-59 * * * * root /root/taskSpooler.sh
################################################################################
# SCRIPT CONFIGURATION                                                         #
################################################################################

# Enter the spooler file
readonly CMDSPOOLER='/tmp/commandSpooler.run'
# Max lines in log
readonly MAXLINES=30000
# Where should the actions be temporal logged
readonly LOGNAME='/root/commandSpooler.log'

################################################################################
# SCRIPT FUNCTIONS                                                             #
################################################################################

###Function to clear the log
function clearLog() {
  echo 'Log cleared' > $LOGNAME
  echo 'Script will run ' $1 ' times then will clear itself'>> $LOGNAME
}

################################################################################
# SCRIPT EXCECUTION STARTS HERE                                                #
################################################################################
## We check if the logfile exists, otherwise we create it
if [ ! -f $LOGNAME ]; then
	touch $LOGNAME
fi

##CLEAR THE LOG IF LINES > MAXLINES
loglines=`wc -l < $LOGNAME`
if [ $loglines -eq $MAXLINES ]; then
	clearlog
fi

if [ ! -f $CMDSPOOLER ]; then
	#mv /var/lib/mysql/aria_log_control /var/lib/mysql/aria_log_control.moved
	exit 0
else
  	#mv /var/lib/mysql/aria_log_control /var/lib/mysql/aria_log_control.moved
	## We remove the file if its empty.
	cmdlines=`wc -l < $CMDSPOOLER`
	if [ $cmdlines -eq 0 ]; then
			rm $CMDSPOOLER
			exit 0
	fi
	# Theres something to be done
	cat $CMDSPOOLER | while read LINE
	do
		execcmd=`$LINE` 
		echo "Command executed: "$LINE" Exit code: "$? > $LOGNAME
		#We remove that line after executed
		sed -i '$d' $CMDSPOOLER
	done
	exit 1
fi

