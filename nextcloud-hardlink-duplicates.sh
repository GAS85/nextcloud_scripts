#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty

NextCloudPath=/var/www/nextcloud

# Do not touch (true) appdata_XXXXXX directory, e.g. previews and system/app files.
# If you set false, appdata and previews will be also evaluated
appdata=true

###

LOCKFILE=/tmp/nextcloud-hardlink-duplicates.tmp

# Check if config.php exist
[[ -r "$NextCloudPath"/config/config.php ]] || { echo >&2 "Error - config.php could not be read under "$NextCloudPath"/config/config.php. Please check the path and permissions"; exit 1; }

# Fetch data directory place from the config file
DataDirectory=$(grep datadirectory "$NextCloudPath"/config/config.php | cut -d "'" -f4)

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run more then 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
	echo "WARNING - Other instance is still active, exiting."
	exit 1
fi

# Check if OCC is reacheble
if [ ! -w "$NextCloudPath/occ" ]; then
	echo "ERROR - Command $NextCloudPath/occ not found. Make sure taht path is corrct."
	exit 1
else
	if [ "$EUID" -ne "$(stat -c %u $NextCloudPath/occ)" ]; then
		echo "ERROR - Command $NextCloudPath/occ not executable for current user.
	Make sure that user has right to execute it.
	Script must be executed as $(stat -c %U $NextCloudPath/occ)."
		exit 1
	fi
fi

maintenance_on () {

	echo .
	php $NextCloudPath/occ maintenance:mode --on
	echo .
	sleep 5

}

maintenance_off () {

	echo .
	php $NextCloudPath/occ maintenance:mode --off
	echo .

}

find_duplicates () {

	cd $DataDirectory
    
	if [ "$appdata" == true ]; then

	    # You can also exclude updater path by added ! -path "./updater-*"
    	find . ! -path "./appdata_*" -print0 |xargs -0 rdfind -makehardlinks true

	else

		rdfind -makehardlinks true $DataDirectory

	fi

}

InstallerCheck () {

	# Check if all Programms are installed
	hash $1 2>/dev/null || { echo >&2 "It requires $1 but it's not installed. Aborting."; exit 1; }

}

InstallerCheck php

InstallerCheck rdfind

touch $LOCKFILE

maintenance_on

find_duplicates

maintenance_off

rm $LOCKFILE

exit 0