#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty.
# Original tread https://help.nextcloud.com/t/howto-get-notifications-for-system-updates/10299 

# Adjust to your NC installation
	# Administrator User to notify
USER="admin"
	# Your NC OCC Command path
COMMAND=/var/www/nextcloud/occ
	# Your PHP location
PHP=/usr/bin/php
	# Path to NC log file
LOGFILE=/var/www/nextcloud/data/nextcloud.log

################

. nextcloud-scripts-config.conf

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

#PACKAGES=$(apt list --upgradable 2>&1)
PACKAGESRAW=$(apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }' 2>&1)
NUM_PACKAGES=$(echo "$PACKAGESRAW" | wc -l)
PACKAGES=$(echo "$PACKAGESRAW"|xargs)
READOnlyDev=$(mount | grep "/dev" | grep '(ro,' | wc -l)

if [ "$PACKAGES" != "" ]; then

	UPDATE_MESSAGE=$(echo "Packages to update: $PACKAGES" | sed -r ':a;N;$!ba;s/\n/, /g')
	$PHP $COMMAND notification:generate $USER "$NUM_PACKAGES packages require to be updated" -l "$UPDATE_MESSAGE"
	echo \{\"app\":\"Notification\",\"message\":\""+++ $NUM_PACKAGES packages require to be updated. $UPDATE_MESSAGE +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

elif [ -f /var/run/reboot-required ]; then

	$PHP $COMMAND notification:generate $USER "System requires a reboot"

elif [ "$READOnlyDev" -gt 0 ]; then

	$PHP $COMMAND notification:generate $USER "WARNING! Some of your Partitions are in Read Only mode!"

fi

exit 0
