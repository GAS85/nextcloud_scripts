#!/bin/bash

COMMAND=/var/www/nextcloud/occ
OPTIONS="files:scan"
LOCKFILE=/tmp/nextcloud_file_scan
LOGFILE=/var/www/nextcloud/data/nextcloud.log
CRONLOGFILE=/var/log/next-cron.log

#[ -f "$LOCKFILE" ] && exit

if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run longer than 10 days due to lock file.
	find "$LOCKFILE" -mtime +10 -type f -delete
    exit 1
fi

touch $LOCKFILE
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Filescan +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE

# scan all files of all users (Takes ages)
#php $COMMAND $OPTIONS --all >> $CRONLOGFILE


# scan all files of selected users
#php $COMMAND $OPTIONS [user_id] >> $CRONLOGFILE
# e.g. php $COMMAND $OPTIONS user1 >> $CRONLOGFILE


# scan all EXTERNAL files of selected users
# how to get mounted externals? --> sudo -u www-data php occ files_external:list | awk -F'|' '{print $8 $3}'
#sudo -u www-data php occ files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}'
# "user_id/files/path"
#   or
# "user_id/files/mount_name"
#   or
# "user_id/files/mount_name/path"

#get ALL external mounting points and users
php $COMMAND files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}' > $LOCKFILE

#rescan all shares
cat $LOCKFILE | while read line ; do php $COMMAND $OPTIONS --path="$line" >> $CRONLOGFILE ; done

end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Filescan Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

# OPTIONAL
### Start Cache cleanup
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Files Cache cleanup +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
start=`date +%s`
date >> $CRONLOGFILE
php $COMMAND files:cleanup >> $CRONLOGFILE
end=`date +%s`
echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Files Cache cleanup Completed. Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
### FINISCH Cache cleanup


#echo -------------------------------------------------- >> $LOGFILE
rm $LOCKFILE
