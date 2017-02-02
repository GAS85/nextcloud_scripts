#!/bin/bash

COMMAND=/var/www/nextcloud/occ
OPTIONS="preview:pre-generate"
LOCKFILE=/tmp/nextcloud_preview
LOGFILE=/var/www/nextcloud/data/nextcloud.log

[ -f "$LOCKFILE" ] && exit

touch $LOCKFILE
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Preview generation +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
php $COMMAND $OPTIONS >> /var/log/next-cron.log
end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Preview generation Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
#echo -------------------------------------------------- >> $LOGFILE
rm $LOCKFILE
