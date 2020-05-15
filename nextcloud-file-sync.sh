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
COMMAND=/var/www/nextcloud/occ
	# Your NC log file path
LOGFILE=/var/www/nextcloud/data/nextcloud.log
	# Your log file path for other output if needed
CRONLOGFILE=/var/log/next-cron.log
	# If you want to perform cache cleanup, please change CACHE value to 1
CACHE=0
	# Your PHP location
PHP=/usr/bin/php

. nextcloud-scripts-config.conf

# Live it like this
OPTIONS="files:scan"
LOCKFILE=/tmp/nextcloud_file_scan
KEY="$1"
SECONDS=0

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run longer than 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
	exit 1
fi

# Check if OCC is reacheble
if [ ! -w "$COMMAND" ]; then
	echo "ERROR - Command $COMMAND not found. Make sure taht path is corrct."
	exit 1
else
	if [ "$EUID" -ne "$(stat -c %u $COMMAND)" ]; then
		echo "ERROR - Command $COMMAND not executable for current user.
	Make sure that user has right to execute it.
	Script must be executed as $(stat -c %U $COMMAND)."
		exit 1
	fi
fi

# Fetch data directory and logs place from the config file
ConfigDirectory=$(echo $COMMAND | sed 's/occ//g')/config/config.php
DataDirectory=$(grep datadirectory $ConfigDirectory | cut -d "'" -f4)
LogFilePath=$(grep logfile $ConfigDirectory | cut -d "'" -f4)
if [ LogFilePath = "" ]; then
	LOGFILE=$DataDirectory/nextcloud.log
else
	LOGFILE=$LogFilePath
fi

# Check if php is executable
if [ ! -x "$PHP" ]; then
	echo "ERROR - PHP not found, or not executable."
	exit 1
fi

# Check if NC Log file is writable
if [ ! -w "$LOGFILE" ]; then
	echo "WARNING - could not write to Log file $LOGFILE, will drop log messages. Is User Correct? Current log file owener is $(stat -c %U $LOGFILE)"
	LOGFILE=/dev/null
fi

# Check if CRON Log file is writable
if [ ! -w "$CRONLOGFILE" ]; then
	echo "WARNING - could not write to Log file $CRONLOGFILE, will drop log messages. Is User Correct? Current log file owener is $(stat -c %U $CRONLOGFILE)"
	CRONLOGFILE=/dev/null
fi

# Put output to Logfile and Errors to Lockfile as per https://stackoverflow.com/questions/18460186/writing-outputs-to-log-file-and-console
exec 3>&1 1>>${CRONLOGFILE} 2>>${CRONLOGFILE}

touch $LOCKFILE

reqId=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c20)

echo \{\"reqId\":\"$reqId\",\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Filescan +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

date >> $CRONLOGFILE

# scan all files of selected users
#$PHP $COMMAND $OPTIONS [user_id] >> $CRONLOGFILE
# e.g. php $COMMAND $OPTIONS user1 >> $CRONLOGFILE


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
	$PHP $COMMAND files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}' > $LOCKFILE
		
	# rescan all shares
	cat $LOCKFILE | while read line ; do $PHP $COMMAND $OPTIONS --path="$line"; done
else
	# scan all files of all users (Takes ages)
	if [ "$KEY" == "--all" ]; then
		$PHP $COMMAND $OPTIONS --all
	fi
fi

duration=$SECONDS

echo \{\"reqId\":\"$reqId\",\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Filescan Completed. Execution time: $(($duration / 60)) minutes and $(($duration % 60)) seconds +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

# OPTIONAL
### Start Cache cleanup

if [ "$CACHE" -eq "1" ]; then
	echo \{\"reqId\":\"$reqId\",\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Files Cache cleanup +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
	SECONDS=0
	date >> $CRONLOGFILE
	$PHP $COMMAND files:cleanup >> $CRONLOGFILE
	duration=$SECONDS
	echo \{\"reqId\":\"$reqId\",\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Files Cache cleanup Completed. Execution time: $(($duration / 60)) minutes and $(($duration % 60)) seconds +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
fi
### FINISCH Cache cleanup

rm $LOCKFILE

exit 0
