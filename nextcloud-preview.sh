#!/bin/bash

# Path to your occ command.
# E.g. /var/www/nextcloud/occ
COMMAND=/var/www/nextcloud/occ

# # Possible options:
#  preview:pre-generate - to generate preview to all NEW files
#  preview:generate-all - to rescan whole system and generate previews 
OPTIONS="preview:pre-generate"
#OPTIONS="preview:generate-all"

# # use to see all touched files
# Possible values (e.g. Debug level) -v, -vv, -vvv.
#DEBUG="-vvv"

# Path to NC log file
LOGFILE=/var/www/nextcloud/data/nextcloud.log

# Path to log file for this script
CRONLOGFILE=/var/log/next-cron.log

LOCKFILE=/tmp/nextcloud_preview

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run more then 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
	echo "WARNING - Other instance is still active, exiting." >> $CRONLOGFILE
	exit 1
fi

touch $LOCKFILE

echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Preview generation +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE

php $COMMAND $OPTIONS $DEBUG >> $CRONLOGFILE

end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Preview generation Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

rm $LOCKFILE

exit 0
