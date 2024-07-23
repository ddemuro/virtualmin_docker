#!/bin/bash
# Update a bind DNS zone file
# Bruno Bense
#####Extended by Derek Demuro

################################################################################
# README (OR "HOW TO USE THIS SCRIPT") !! THIS BIT IS IMPORTANT !!             #
################################################################################
# This script is pretty straightforward. It checks if your current IP address is
# different since the last time it ran. The previous IP address is stored on a
# TXT record on your zone file, called "dynip". It is highly recomended that you
# follow this route, so BEFORE ATTEMPTING ANYTHING CREATE THE TXT RECORD 
# mentioned above, otherwise it won't work.
#
# Once that's done, you'll find some variables on the section below that you 
# MUST set according to your own configuration and preferences. Once that's done
# you can try to call this script from the command line to make sure everything 
# runs O.K.
#
# Finally, you'll need a way to run this script periodically. The easiest way
# is using crontab (or your distro's equivalent). The following example runs
# this script every 2 minutes
#
# */2 *   * * *   root    /home/example/dynDNS.sh
#
# NOTE: You will probably need to run this script as root, otherwise you 
# probably won't be able to modify the bind zone files.
#
# Keep in mind that this script uses different exit codes representing the 
# different errors that can happen. These are:
#
#   0:  Everything completed succesfully (without errors.)
#   1:  Failure to replace the IP addresses on the zone file.
#   2:  Failure to make a backup copy of the zone file.
#   3:  Failure to restart the bind DNS server.
#   4:  Failure to retrieve external IP address.
#
################################################################################
# SCRIPT CONFIGURATION                                                         #
################################################################################

# The ABSOLUTE path of the zone file containing the records to update and list 
#file containing zones to be changed.
readonly zoneFilesL='/opt/scripts/lists/zonesList.lst'
readonly zoneFilesRoute='/var/lib/bind/'
readonly zoneFilesList=$zoneFilesL

# If you wish to make a backup of the zone file before any modification.
# Possible values: true (default), false.
readonly makeBackup='true'
##@@@@REMEMBER THAT PATH MUST EXIST OTHERWISE WILL FAIL@@@@#####
# and the absolute path to the backup directory.
readonly backupDirectory='/opt/scripts/backup/'

# The script will check if the IP addresses have changed since the last time to 
# avoid useless mofications to the zone file and DNS server restarts.
# You may want to force the update for debugging purposes.
# Possible values: true, false (defualt).
readonly forceUpdate='false'

# That's all. You shouldn't modify this script past this point, unless you know
# what you're doing.

## Local var (bind needs restart)
bindres=`wc -l $zoneFilesList | awk '{ print $1 }'`

# PARCHE EN LA TURBIA: hasta no hacer andar el export, vamos a crear un archivo
# para determinar cuando es necesario reiniciar bind. Ah, vamos a ponerle un
# nombre inecesariamente largo al archivo, just because.
touch bindRestartFlagFile
rm bindRestartFlagFile

################################################################################
# SCRIPT CONSTANTS (DO NOT MODIFY)                                             #
################################################################################
readonly regExIP="^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$"
readonly regExSerial='[0-9]\{10\}$'

################################################################################
# SCRIPT FUNCTIONS (DO NOT MODIFY)                                             #
################################################################################
function validarIP(){
	# USO: validarIP <direcciónIP>	
	# DESCRIPCION: Recibe una IP y devuelve 0 si es valida o 1 si es invalida
    
	echo $1 | grep $regExIP >/dev/null
	if [ $? -eq 0 ]
	then
		for i in `seq 1 4`
		do
			octet=`echo $1 | cut -d"." -f $i`
			if [ $octet -ge 256 ] 
			then
				return 1
			fi
		done
		return 0
	else
		return 1
	fi	
}

function incrementSOA(){
    # USAGE: incrementSOA
    # DESCRIPTION: Increments the zone file serial number by 1.

    newSerial=`grep $regExSerial $zoneFilesRoute$LINE`
    serial=$newSerial
    ((newSerial++)) 
    echo "Updating serial number from" $serial "to" $newSerial
    sed -i s/"$serial"/"$newSerial"/ "$zoneFilesRoute$LINE"
    if [ $? -ne 0 ]
    then
	echo "$(tput setaf 1)There was an error while incrementing the zone serial number. $(tput sgr0)"
	echo "Zone transfer won't happen unless the serial number is updated."
	return 1
    fi
    return 0
}

function restartBind(){
    # USAGE: restartBind
    # DESCRIPTION: Restarts bind.
    echo 'restarting bind nao'
    service bind9 stop
    messages=`service bind9 start 2>&1`

    if [ $? -ne 0 ]
    then
	    echo "$(tput setaf 1)Failed to restart the bind DNS server. $(tput sgr0)"
	    echo ""
	    echo $messages
	    echo ""
	    echo "At this point, bind may not be running! Exiting with code 3."
	    exit 3
    fi
    echo 'bind is happy'
    return 0
}    
################################################################################
# SCRIPT EXCECUTION STARTS HERE                                                #
################################################################################

# DEBUG: echo some cool variables

echo 'zoneFilesList:' $zoneFilesList

# END DEBUG
##IF we pass by parameter IP, we validate it if SUCCESS we update zones
##IF IP Invalid, we use normal resolution style.
if [ "$1" = '' ]
then
    IPS='http://dynupdate.no-ip.com/ip.php'
    currentIP=`curl -s $IPS | awk '{ print $1 }'`
else
    currentIP=$1
fi


# If for any reason, the primary method for getting the public IP address fails,
# we use the alternative

validarIP "$currentIP"
if [ $? -ne 0 ]
then
	echo "$(tput setaf 3)Primary external IP resolution method failed. (Got $currentIP )$(tput sgr0)"
	echo "Attempting alternative resolution..."
  IPS='http://dynupdate.no-ip.com/ip.php'
  currentIP=`curl -s $IPS | awk '{ print $1 }'`
  validarIP "$currentIP"
 	if [ $? -ne 0 ]
	then
	    echo "$(tput setaf 3)Primary external IP resolution method failed. (Got $currentIP )$(tput sgr0)"
	    echo "Attempting alternative resolution..."
	    currentIP=`curl ifconfig.me` >/dev/null
	    validarIP "$currentIP"
	fi
	if [ $? -ne 0 ]
	then
		# If everything fails, we're doomed. Maybe we're offline?
		echo "$(tput setaf 1)The script failed at getting the external IP address! (Got $currentIP )$(tput sgr0)"
		echo "The update process for $zoneFilesRoute$zoneFilesList was interrupted."
		echo "Exiting with code 4."		
		exit 4	
	fi
fi	

cat $zoneFilesList | while read LINE
do
    echo $LINE

    previousIP=`grep 'dynip' $zoneFilesRoute$LINE | cut -d\" -f2`

    if [[ "$previousIP" != "$currentIP" || "$forceUpdate" = "true" ]]
    then
	    echo "IP Address to replace:" $previousIP

	    if [ "$makeBackup" = "true" ]
	    then
		    # We make a backup of the zone file to the backupDirectory defined above, just in case.
		    cp "$zoneFilesRoute$LINE" $backupDirectory"`date +%Y%m%d_%H%M%S`"
		    if [ $? -ne 0 ]
		    then
			    echo "$(tput setaf 1)There was an error while making the backup file for $zoneFilesRoute$LINE.$(tput sgr0)"
			    echo "The update process for "$zoneFilesRoute$LINE" was interrupted."
			    echo "Exiting with code 2."
			    exit 2
		    fi
	    fi

	    # Replace the IP in the zoneFile
	    sed -i s/"$previousIP"/"$currentIP"/g $zoneFilesRoute$LINE
	    if [ $? -ne 0 ]
	    then
		    echo "$(tput setaf 1)There was an error while replacing the IP addresses on $zoneFilesRoute$LINE$.(tput sgr0)"
		    echo "$(tput setaf 3)WARNING!$(tput sgr0) The zone file may contain invalid data!"
		    echo "Usless data: previous IP is $previousIP, current IP is $currentIP ."
		    echo "Exiting with code 1."
		    exit 1
	    fi
	    touch bindRestartFlagFile
	
	echo "Incrementing zone serial number."
	incrementSOA
    else
        echo "The IP address to replace $previousIP and the current IP address $currentIP seems to be the same."
	echo "Exiting with code 0."
    fi
done 

if [ -e bindRestartFlagFile ]
then
	restartBind
fi
rm bindRestartFlagFile

#If everything ok, exit with 0
exit 0
