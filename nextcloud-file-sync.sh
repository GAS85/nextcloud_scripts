#!/bin/bash

# By Georgiy Sitnikov.
#
# Will do external ONLY shares rescan for nextcloud and put execution information in NC log.
# If you would like to perform WHOLE nextcloud rescan, please add --all to command, e.g.:
# ./nextcloud-file-sync.sh --all
#
# AS-IS without any warranty

# Adjust to your NC installation
	# Your NC OCC Command path
Command=/var/www/nextcloud/occ
	# Your NC log file path
LogFile=/var/www/nextcloud/data/nextcloud.log
	# Your log file path for other output if needed
CronLogFile=/var/log/next-cron.log
	# If you want to perform cache cleanup, please change CACHE value to 1
CACHE=0
	# Your PHP location
PHP=/usr/bin/php

CentralConfigFile="/etc/nextcloud-scripts-config.conf"

if [ -f "$CentralConfigFile" ]; then

	. $CentralConfigFile

fi

# Live it like this
OPTIONS="files:scan"
LOCKFILE=/tmp/nextcloud_file_scan
KEY="$1"
SECONDS=0
LvL=1

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run longer than 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
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
if [ “$LogFilePath” = “” ]; then
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

# Put output to Logfile and Errors to Lockfile as per https://stackoverflow.com/questions/18460186/writing-outputs-to-log-file-and-console
exec 3>&1 1>>${CronLogFile} 2>>${CronLogFile}

touch $LOCKFILE

reqId=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c20)

messageToLog () {

	# ${0##*/} from https://stackoverflow.com/questions/192319/how-do-i-know-the-script-file-name-in-a-bash-script
	echo \{\"reqId\":\"$reqId\",\"user\":\"occ\",\"app\":\"${0##*/}\",\"url\":\"$Command $OPTIONS\",\"message\":\"$Message\",\"level\":$LvL,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LogFile

}

Message="+++ Starting Cron Filescan +++"
messageToLog
date >> $CronLogFile

# scan all files of selected users
#$PHP $Command $OPTIONS [user_id] >> $CronLogFile
# e.g. php $Command $OPTIONS user1 >> $CronLogFile


# scan all EXTERNAL files of selected users
# how to get mounted externals? --> sudo -u www-data php occ files_external:list | awk -F'|' '{print $8 $3}'
#sudo -u www-data php occ files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}'
# "user_id/files/path"
#   or
# "user_id/files/mount_name"
#   or
# "user_id/files/mount_name/path"

if [ "$KEY" != "--all" ]; then

	# get ALL external mounting points and users
	$PHP $Command files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}' | grep -v "," > $LOCKFILE
    # get shares that belongs to more than 1 user
    $PHP $Command files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}' | grep "," | awk -F',' '{print $NF}' >> $LOCKFILE

	# rescan all shares
	cat $LOCKFILE | while read line ; do $PHP $Command $OPTIONS --path="$line"; done

else

	# scan all files of all users (Takes ages)
	if [ "$KEY" == "--all" ]; then

		$PHP $Command $OPTIONS --all

	fi

fi

duration=$SECONDS
Message="+++ Cron File scan Completed. Execution time: $(($duration / 60)) minutes and $(($duration % 60)) seconds +++"
messageToLog

# OPTIONAL
### Start Cache cleanup

if [ "$CACHE" -eq "1" ]; then

	Message="+++ Starting Cron Files Cache cleanup +++"
	messageToLog
	SECONDS=0
	date >> $CronLogFile

	$PHP $Command files:cleanup >> $CronLogFile

	duration=$SECONDS
	Message="+++ Cron Files Cache cleanup Completed. Execution time: $(($duration / 60)) minutes and $(($duration % 60)) seconds +++"
	messageToLog

fi
### FINISH Cache cleanup

rm $LOCKFILE

exit 0