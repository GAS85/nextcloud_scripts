#!/bin/bash

# By Georgiy Sitnikov.
#
# Will do system backup and upload encrypted to mega - NEEDS megatools
#
# AS-IS without any warranty

nonce=$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 )

# PLEASE Create "Backup" Folder in Mega

# Please do not use root folder for backup
WORKINGDIR=/some/folder
recipients="your@email.com"
subject="System backup was done"
from="noreplay@your.domain"
megalogin="yyyyyy@TOBE.PROVIDED"
megapass="xxxxxxTOBEPROVIDED"
logfile=/var/log/backup_$nonce.log

### Please do not edit following Lines:
LOCKFILE=/tmp/sysbackup
EMAILFILE=/tmp/sysbackup.mail
extension=.tar.gpg
BACKUPNAME=backup-$(date +"%Y-%m-%d")_$nonce$extension
#Check if Backup file name already taken
if [ -f "$BACKUPNAME" ]; then
        # Added time to Backup name
	echo WARNING - Backup file $BACKUPNAME exist, will take another name to create backup.
	BACKUPNAME=backup-$(date +"%Y-%m-%d_%T")_$nonce$extension
fi
ToFind="$(echo $BACKUPNAME | cut -c1-6)*$nonce$extension"

#[ -f "$LOCKFILE" ] && exit
if [ -f "$LOCKFILE" ]; then
	# Remove lock file if script fails last time and did not run longer than 35 days due to lock file.
	find "$LOCKFILE" -mtime +35 -type f -delete
	exit 1
fi

#Check if Working dir exist
if [ ! -d "$WORKINGDIR" ]; then
	echo "Directory $WORKINGDIR does not exist"
	exit 1
fi

touch $LOCKFILE
touch $EMAILFILE

start=`date +%s`

echo "$(date) - INFO - The backup process ($BACKUPNAME) has being started." >> $logfile

# Random password generator. 48 is a password lenght 
pass="$(gpg --armor --gen-random 1 48)"

cd $WORKINGDIR

# List excluded of folders
excludeFromBackup="--exclude=$WORKINGDIR\
 --exclude=/var/www/nextcloud/data\
 --exclude=/proc\
 --exclude=/tmp\
 --exclude=/mnt\
 --exclude=/dev\
 --exclude=/sys\
 --exclude=/run\
 --exclude=/media\
 --exclude=/var/log\
 --exclude=/var/cache/apt/archives\
 --exclude=/usr/src/linux-headers*\
 --exclude=/home/*/.gvfs\
 --exclude=/home/*/.cache\
 --exclude=/home/*/.local/share/Trash\"

# Do System backup
tar -cvp $excludeFromBackup --one-file-system / | gpg --passphrase "$pass" --symmetric --no-tty -o $BACKUPNAME 2 >> $LOCKFILE

middle=`date +%s`

#Upload backup to Mega
#megaput -u $megalogin -p $megapass --path /Root/Backup $BACKUPNAME 2>>$LOCKFILE
upload_command="megaput -u $megalogin -p $megapass --path /Root/Backup $BACKUPNAME"

NEXT_WAIT_TIME=10
until $upload_command || [ $NEXT_WAIT_TIME -eq 4 ]; do
   sleep $(( NEXT_WAIT_TIME++ ))
   echo "$(date) - ERROR - Mega Upload was failed, will retry after 10 seconds ($BACKUPNAME)." >> $logfile
done

#delete local old backups
# +45 is older than 45 days - basically any other backup.
find "$ToFind" -mtime +45 -exec rm {} \; 2>>$LOCKFILE
#find backup*gpg -mtime +45 -exec rm {} \; 2>>$LOCKFILE

#put collected data into logfile
[ -s $LOCKFILE ] && cat $LOCKFILE) >> $logfile

end=`date +%s`

#Email Header
echo "To: $recipients" > $EMAILFILE
echo "FROM: $from" >> $EMAILFILE
echo "Subject: $subject" >> $EMAILFILE
echo "MIME-Version: 1.0" >> $EMAILFILE
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"' >> $EMAILFILE
echo >> $EMAILFILE
echo '---q1w2e3r4t5' >> $EMAILFILE
echo "Content-Type: text/html" >> $EMAILFILE
echo "Content-Disposition: inline" >> $EMAILFILE
echo "" >> $EMAILFILE
echo 'The backup was created with password: '"'$pass'"'<br>' >> $EMAILFILE
echo "It took `expr $middle - $start`s to create and `expr $end - $middle`s to upload backup file, or `expr $end - $start`s at all.<br>" >> $EMAILFILE
echo "Have a nice day and check some statistic.<br>">> $EMAILFILE
echo "<br>">> $EMAILFILE
echo "Backup size: $(du -h $BACKUPNAME | awk '{printf "%s",$1}').<br>" >> $EMAILFILE

sha=$(sha256sum $BACKUPNAME | awk '{printf "%s",$1}' | tr 'a-z' 'A-Z')

echo "SHA256 of backup file: $sha.<br>" >> $EMAILFILE
echo "<br>">> $EMAILFILE
echo "Space information: $(megadf -u $megalogin -p $megapass -h).<br>" >> $EMAILFILE
[ -s $LOCKFILE ] && echo "Other info: $(cat $LOCKFILE).<br>" >> $EMAILFILE
#echo "<br>">> $EMAILFILE

#send email with password
cat $EMAILFILE | /usr/sbin/sendmail $recipients
#cat $EMAILFILE

#remove temporary files
rm $LOCKFILE
rm $EMAILFILE

# Opt: save password locally if Email fails, or you do not want to send it.
echo "$(date) - The backup ($BACKUPNAME) was created with password: $pass - SHA256 of backup file: $sha" >> $WORKINGDIR/passes.txt

exit 0
