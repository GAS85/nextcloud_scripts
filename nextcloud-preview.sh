#!/bin/bash

COMMAND=/var/www/nextcloud/occ
OPTIONS="preview:pre-generate"
# use to see all touched files
#OPTIONS="preview:pre-generate -vvv"
LOCKFILE=/tmp/nextcloud_preview
LOGFILE=/var/www/nextcloud/data/nextcloud.log
CRONLOGFILE=/var/log/next-cron.log
NEXTPATH=/var/www/nextcloud/data/appdata_<INSTANCE>/preview

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run longer than 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
  exit 1
fi

touch $LOCKFILE
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Preview generation +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE

php $COMMAND $OPTIONS >> $CRONLOGFILE

end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Preview generation Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

rm $LOCKFILE
