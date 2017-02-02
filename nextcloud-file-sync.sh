#!/bin/bash

COMMAND=/var/www/nextcloud/occ
OPTIONS="files:scan --all"
LOCKFILE=/tmp/nextcloud_file_scan
LOGFILE=/var/www/nextcloud/data/nextcloud.log

[ -f "$LOCKFILE" ] && exit

touch $LOCKFILE
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Filescan +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
php $COMMAND $OPTIONS >> /var/log/next-cron.log
end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Filescan Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
#echo -------------------------------------------------- >> $LOGFILE
rm $LOCKFILE
