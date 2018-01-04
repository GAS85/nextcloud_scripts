#!/bin/bash

WORKINGDIR=/media/backup
CACTIrraDIR=/var/lib/cacti/rra
LOCKFILE=/tmp/zipping
EMAILFILE=/tmp/zipping.email
BACKUPNAME=backup-$(date +"%Y-%m-%d").zip
ATTACHDIR=/files/to/be/attached
recipients="user1@gmail.com,user2@gmail.com,user3@gmail.com"
subject="MySQL backup was done"
from="noreplay@nobody.net"
#megapass="xxxxxxx"
#megalogin="zzzzzzz"

[ -f "$LOCKFILE" ] && exit

touch $LOCKFILE
touch $EMAILFILE

#MySQL all DB backup and gzip if needed
#mysqldump –all-databases | gzip > $WORKINGDIR/backup-$(date +"%Y-%m-%d").sql.gz

#Random password
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
pass="$({ choose '!@#$%^\&'
  choose '0123456789'
  choose 'abcdefghijklmnopqrstuvwxyz'
  choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for i in $( seq 1 $(( 4 + RANDOM % 16 )) )
     do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
     done
 } | sort -R | awk '{printf "%s",$1}')"

#Cacti Backup -- http://lifein0and1.com/2008/05/15/migrating-cacti-from-one-server-to-another/

#This is cacti working dir
cd $CACTIrraDIR

ls -1 *.rrd | awk '{print "rrdtool dump "$1" &gt; "$1".xml"}' | sh -x
tar -czvf $WORKINGDIR/rrd.tgz *.rrd.xml
rm *.rrd.xml

#end Cacti backup

#to restore Cacti RRDs
#copy xml into /var/lib/cacti/rra/
#ls -1 *.rrd.xml | sed 's/\.xml//' | awk '{print "rrdtool restore "$1".xml "$1}' | sh -x
#chown www-data:www-data *.rrd

cd $WORKINGDIR

#zipping with password from above
zip --password $pass $BACKUPNAME *gz 1>$LOCKFILE

#Upload to Mega
#megaput --no-progress --path /Root/Backup $BACKUPNAME >>$LOCKFILE
#megaput -u $megalogin -p $megapass --no-progress --path /Root/Backup $BACKUPNAME 2>>$LOCKFILE
megaput -u $megalogin -p $megapass --path /Root/Backup $BACKUPNAME 2>>$LOCKFILE

#delete local old backups
# +15 is older than 15 days
find backup*zip -mtime +15 -exec rm {} \;

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
echo "Space information: $(megadf -u $megalogin -p $megapass -h).<br>" >> $EMAILFILE
echo "Other info: $(cat $LOCKFILE).<br>" >> $EMAILFILE
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
rm $LOCKFILE
rm $EMAILFILE
exit 0
