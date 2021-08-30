#!/bin/bash

# # Possible options:
#  preview:pre-generate - to generate preview to all NEW files
#  preview:generate-all - to rescan whole system and generate previews 
OPTIONS="preview:pre-generate"
#OPTIONS="preview:generate-all"

# # use to see all touched files
# Possible values (e.g. Debug level) -v, -vv, -vvv.
#DEBUG="-vvv"

# Path to your occ command.
# E.g. /var/www/nextcloud/occ
Command=/var/www/nextcloud/occ

# Path to NC log file
LogFile=/var/www/nextcloud/data/nextcloud.log

# Optional:
# Path to log file for this script
CronLogFile=/var/log/next-cron.log

# Your PHP location if different
PHP=/usr/bin/php

### Please do not touch under this line ###

CentralConfigFile="/etc/nextcloud-scripts-config.conf"

if [ -f "$CentralConfigFile" ]; then

	. $CentralConfigFile

fi

LOCKFILE=/tmp/nextcloud_preview
LvL=1
SECONDS=0

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run more than 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
	echo "WARNING - Other instance is still active, exiting." >> $CronLogFile
	exit 1
fi

# Check if OCC is reachable
if [ ! -w "$Command" ]; then
	echo "ERROR - Command $Command not found. Make sure that path is correct."
	exit 1
else
	if [ "$EUID" -ne "$(stat -c %u $Command)" ]; then
		echo "ERROR - Command $Command not executable for current user.
	Make sure that user has right to execute it.
	Script must be executed as $(stat -c %U $Command)."
		exit 1
	fi
fi

# Fetch data directory and logs place from the config file
ConfigDirectory=$(echo $Command | sed 's/occ//g')/config/config.php
# Check if config.php exist
[[ -r "$ConfigDirectory" ]] || { echo >&2 "Error - config.php could not be read under "$ConfigDirectory". Please check the path and permissions"; exit 1; }
DataDirectory=$(grep datadirectory $ConfigDirectory | cut -d "'" -f4)
LogFilePath=$(grep logfile $ConfigDirectory | cut -d "'" -f4)
if [ LogFilePath = "" ]; then
	LogFile=$DataDirectory/nextcloud.log
else
	LogFile=$LogFilePath
fi

# Check if php is executable
if [ ! -x "$PHP" ]; then
	echo "ERROR - PHP not found, or not executable."
	exit 1
fi

# Check if NC Log file is writable
if [ ! -w "$LogFile" ]; then
	echo "WARNING - could not write to Log file $LogFile, will drop log messages. Is User Correct? Current log file owner is $(stat -c %U $LogFile)"
	LogFile=/dev/null
fi

# Check if CRON Log file is writable
if [ ! -w "$CronLogFile" ]; then
	echo "WARNING - could not write to Log file $CronLogFile, will drop log messages. Is User Correct? Current log file owner is $(stat -c %U $CronLogFile)"
	CronLogFile=/dev/null
fi

touch $LOCKFILE

reqId=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c20)

messageToLog () {

	# ${0##*/} from https://stackoverflow.com/questions/192319/how-do-i-know-the-script-file-name-in-a-bash-script
	echo \{\"reqId\":\"$reqId\",\"user\":\"none\",\"app\":\"${0##*/}\",\"url\":\"$Command $OPTIONS\",\"message\":\"$Message\",\"level\":$LvL,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LogFile

}

Message="+++ Starting Cron Preview generation +++"
messageToLog
date >> $CronLogFile

$PHP $Command $OPTIONS $DEBUG >> $CronLogFile

duration=$SECONDS
Message="+++ Cron Preview generation Completed. Execution time: $(($duration / 60)) minutes and $(($duration % 60)) seconds +++"
messageToLog

rm $LOCKFILE

exit 0
