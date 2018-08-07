#!/bin/bash

# By Georgiy Sitnikov.
# Will zip and encrypt backup of your MySQL DB and Cacti rrds
# MySQL Backup should be done separatly, or uncommented here as option.
# AS-IS without any warranty

WORKINGDIR=/media/backup
CACTIrraDIR=/var/lib/cacti/rra
ATTACHDIR=/files/to/be/attached
recipients="user1@gmail.com,user2@gmail.com,user3@gmail.com"
subject="MySQL backup done"
from="noreplay@nobody.net"
megapass="xxxxxxx"
megalogin="zzzzzzz"

#BACKUPNAME=backup-$(date +"%Y-%m-%d").gpg
BACKUPNAME=backup-$(date +"%Y-%m-%d")_$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 ).gpg
LOCKFILE=/tmp/zipping
EMAILFILE=/tmp/zipping.email

#Use for MySQL backup and restore from this script
#dbuser="root"
#dbpass="yyyy"

#Check if Backup file name already taken
if [ -f "$BACKUPNAME" ]; then
        # Added time to Backup name
	echo WARNING - Backup file $BACKUPNAME exist, will take another name (add time stamp) to create backup.
	BACKUPNAME=backup-$(date +"%Y-%m-%d_%T")_$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 ).gpg
fi
ToFind="$(echo $BACKUPNAME | cut -c1-6)*$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 ).gpg"

#ToFind="$(echo $BACKUPNAME | cut -c1-6)*$(echo $BACKUPNAME | sed 's/.*\(...\)/\1/')"

[ -f "$LOCKFILE" ] && exit

#Check if Working dir exist
if [ ! -d "$WORKINGDIR" ]; then
	echo "Directory $WORKINGDIR does not exist"
    exit 1
fi

#if [ ! -d "$WORKINGDIR/tmp" ]; then
#	mkdir $WORKINGDIR/tmp
#fi

touch $LOCKFILE
touch $EMAILFILE

#MySQL all DB backup and gzip if needed
#mysqldump --all-databases --single-transaction -u $dbuser -p$dbpass > $WORKINGDIR/tmp/all_databases.sql
#mysqldump –all-databases | tar -czvf > $WORKINGDIR/backup-$(date +"%Y-%m-%d").sql.tgz

#To Restore any DB
#mysql -u root -p
#CREATE DATABASE nextcloud;
#GRANT ALL ON nextcloud.* to 'nextcloud'@'localhost' IDENTIFIED BY 'set_database_password';
#FLUSH PRIVILEGES;
#exit
#mysql -u [username] -p[password] [db_name] < nextcloud-sqlbkp.bak

#Random password 48 is a password lenght 
pass="$(gpg --armor --gen-random 1 48)"

#Cacti Backup -- http://lifein0and1.com/2008/05/15/migrating-cacti-from-one-server-to-another/

#This is cacti working dir
cd $CACTIrraDIR

for entry in *.rrd
do
        rrdtool dump "$entry" > "$entry".xml
done

#tar -cvf $WORKINGDIR/tmp/rrd.tar *.rrd.xml
tar -czvf $WORKINGDIR/rrd.tgz *.rrd.xml
rm *.rrd.xml

#end Cacti backup

#to restore Cacti RRDs
#copy xml into /var/lib/cacti/rra/
#ls -1 *.rrd.xml | sed 's/\.xml//' | awk '{print "rrdtool restore "$1".xml "$1}' | sh -x
#chown www-data:www-data *.rrd

cd $WORKINGDIR

#GPG with password from above
tar -czv *gz | gpg --passphrase "$pass" --symmetric --no-tty -o $BACKUPNAME
#tar -czv tmp/* | gpg --passphrase "$pass" --symmetric --no-tty -o $BACKUPNAME

#Upload to Mega
#megaput --no-progress --path /Root/Backup $BACKUPNAME >>$LOCKFILE
#megaput -u $megalogin -p $megapass --no-progress --path /Root/Backup $BACKUPNAME 2>>$LOCKFILE
#megaput -u $megalogin -p $megapass --path /Root/Backup $BACKUPNAME 2>>$LOCKFILE
upload_command="megaput -u $megalogin -p $megapass --path /Root/Backup $BACKUPNAME"

NEXT_WAIT_TIME=10
until $upload_command || [ $NEXT_WAIT_TIME -eq 4 ]; do
   sleep $(( NEXT_WAIT_TIME++ ))
   #echo "$(date) - ERROR - Mega Upload was failed, will retry after 10 seconds ($BACKUPNAME)." >> $logfile
done

#delete local old backups
# +15 is older than 15 days
find "$ToFind" -mtime +15 -exec rm {} \; 2>>$LOCKFILE
#find backup*gpg -mtime +15 -exec rm {} \;

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
echo "Have a nice day and check some statistic.<br>">> $EMAILFILE
echo "<br>">> $EMAILFILE
echo "Backup size: $(du -h $BACKUPNAME | awk '{printf "%s",$1}').<br>" >> $EMAILFILE
echo "MD5 of Backup file: $(md5sum $BACKUPNAME | awk '{printf "%s",$1}' | tr 'a-z' 'A-Z').<br>" >> $EMAILFILE
echo "Space information: $(megadf -u $megalogin -p $megapass -h).<br>" >> $EMAILFILE
[ -s file.name ] && echo "Other info: $(cat $LOCKFILE).<br>" >> $EMAILFILE
echo "" >> $EMAILFILE

#
# So make man inline file with base64 or uuencode. uuencode will not be read by some programms
#
#echo '---q1w2e3r4t5'
#echo 'Content-Type: image/png; name='$(basename $ATTACH)''
##echo "Content-Transfer-Encoding: uuencode"
#echo "Content-Transfer-Encoding: base64"
#echo 'Content-Disposition: inline; filename='$(basename $ATTACH)''
#echo "Content-ID: <$(basename $ATTACH)>"
#echo '---q1w2e3r4t5--'
#base64 $ATTACH
#uuencode $ATTACH $(basename $ATTACH)
#
# #######################
#
# so make man attachment file with uuencode or base64.
#
##echo '---q1w2e3r4t5'
##echo 'Content-Type: application; name="'$(basename $ATTACH)'"'
##echo "Content-Transfer-Encoding: uuencode"
###echo "Content-Transfer-Encoding: base64"
##echo 'Content-Disposition: attachment; filename="'$(basename $ATTACH)'"'
##echo '---q1w2e3r4t5--'
###base64 $ATTACH
##uuencode $ATTACH $(basename $ATTACH)
#echo '---q1w2e3r4t5'
#echo 'Content-Type: image/png; name='$(basename $ATTACH1)''
#echo "Content-Transfer-Encoding: base64"
#echo 'Content-Disposition: inline; filename='$(basename $ATTACH1)''
#echo "Content-ID: <$(basename $ATTACH1)>"
#echo '---q1w2e3r4t5--'

for entry in "$ATTACHDIR"/graph_*_1.png
do
	export ATTACH=$entry
    echo '---q1w2e3r4t5' >> $EMAILFILE
	echo 'Content-Type: image/png; name='$(basename $ATTACH)'' >> $EMAILFILE
	echo "Content-Transfer-Encoding: base64" >> $EMAILFILE
	echo 'Content-Disposition: inline; filename='$(basename $ATTACH)'' >> $EMAILFILE
	echo "Content-ID: <$(basename $ATTACH)>" >> $EMAILFILE
	echo '---q1w2e3r4t5--' >> $EMAILFILE
	base64 $ATTACH >> $EMAILFILE
done

#send email with password and attachments
cat $EMAILFILE | /usr/sbin/sendmail $recipients

#remove temporary files
#rm $WORKINGDIR/tmp/*
rm $LOCKFILE
rm $EMAILFILE

exit 0
