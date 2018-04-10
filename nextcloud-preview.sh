#!/bin/bash

COMMAND=/var/www/nextcloud/occ
OPTIONS="preview:pre-generate"
# use to see all touched files
#OPTIONS="preview:pre-generate -vvv"
LOCKFILE=/tmp/nextcloud_preview
LOGFILE=/var/www/nextcloud/data/nextcloud.log
CRONLOGFILE=/var/log/next-cron.log
NEXTPATH=/var/www/nextcloud/data/appdata_<INSTANCE>/preview

#[ -f "$LOCKFILE" ] && exit

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
#echo -------------------------------------------------- >> $LOGFILE

# Please use it if you have Gallery app installed
#echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Starting Cron Gallery Preview creation +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE
#start=`date +%s`

#cd $NEXTPATH
#for i in $(find . -name "*-max.png") ; do [[ ! -f $(dirname $i)/$(basename ${i} -max.png).png ]] && ln -s $(dirname `readlink -e ${i}`)/$(basename $i) $(dirname `readlink -e $i`)/$(basename ${i} -max.png).png ; done >> $CRONLOGFILE

#end=`date +%s`
#echo \{\"app\":\"$COMMAND $OPTIONS\",\"message\":\""+++ Cron Gallery preview creation Completed.    Time: `expr $end - $start`s +++"\",\"level\":1,\"time\":\"`date "+%Y-%m-%dT%H:%M:%S%:z"`\"\} >> $LOGFILE

rm $LOCKFILE
