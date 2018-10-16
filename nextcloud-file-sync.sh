#!/bin/bash

# By Georgiy Sitnikov.
#
# Will do external ONLY shares rescan for nextcloud and put execution information in NC log.
# If you would like to perform WHOLE nextcloud rescan, please add -all to command, e.g.:
# ./nextcloud-file-sync.sh -all
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

###################
# Live it like this
OPTIONS="files:scan"
LOCKFILE=/tmp/nextcloud_file_scan
KEY="$1"

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run longer than 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
	exit 1
fi

# Check if OCC is reacheble
if [ ! -x "$COMMAND" ]; then
	echo "ERROR - Command $COMMAND not found. Make sure if path is corrct and user has right to execute it."
	exit 1
fi

# Check if php is executable
if [ ! -x "$PHP" ]; then
	echo "ERROR - PHP not found."
	exit 1
fi

# Check if NC Log file is writable
if [ ! -w "$LOGFILE" ]; then
	echo "WARNING - could not write to Log file $LOGFILE, will drop log messages. Is User Correct?"
	LOGFILE=/dev/null
fi

# Check if CRON Log file is writable
if [ ! -w "$CRONLOGFILE" ]; then
	echo "WARNING - could not write to Log file $CRONLOGFILE, will drop log messages. Is User Correct?"
	CRONLOGFILE=/dev/null
fi

touch $LOCKFILE
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Filescan +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE

# scan all files of all users (Takes ages)

if [ "$KEY" == "-all" ]; then
	$PHP $COMMAND $OPTIONS --all >> $CRONLOGFILE
fi

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

if [ "$KEY" != "-all" ]; then
	# get ALL external mounting points and users
	$PHP $COMMAND files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}' > $LOCKFILE
		
	# rescan all shares
	cat $LOCKFILE | while read line ; do $PHP $COMMAND $OPTIONS --path="$line" >> $CRONLOGFILE ; done
fi

end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Filescan Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

# OPTIONAL
### Start Cache cleanup

if [ "$CACHE" -eq "1" ]; then
	echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Files Cache cleanup +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
	date >> $CRONLOGFILE
	$PHP $COMMAND files:cleanup >> $CRONLOGFILE
	end=`date +%s`
	echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Files Cache cleanup Completed. Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
fi
### FINISCH Cache cleanup

#echo -------------------------------------------------- >> $LOGFILE
rm $LOCKFILE
exit 0
