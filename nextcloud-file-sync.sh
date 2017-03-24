#!/bin/bash

COMMAND=/var/www/nextcloud/occ
OPTIONS="files:scan --all"
LOCKFILE=/tmp/nextcloud_file_scan
LOGFILE=/var/www/nextcloud/nextcloud.log
CRONLOGFILE=/var/log/next-cron.log

[ -f "$LOCKFILE" ] && exit

touch $LOCKFILE
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Filescan +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE
php $COMMAND $OPTIONS >> $CRONLOGFILE
end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Filescan Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
#echo -------------------------------------------------- >> $LOGFILE
rm $LOCKFILE
