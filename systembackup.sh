#!/bin/bash

#Please do not use root folder
WORKINGDIR=/some/folder
recipients="test@gmail.com"
subject="System backup was done"
from="noreplay@nobody.net"
megapass="xxxxxx"
megalogin="yyyyyy"
BACKUPNAME=sys-backup-$(date +"%Y-%m-%d").tar.gz.gpg

###Please do not edit following 3 Lines:
LOCKFILE=/tmp/sysbackup
EMAILFILE=/tmp/sysbackup.mail
ToFind="$(echo $BACKUPNAME | cut -c1-5)*$(echo $BACKUPNAME | sed 's/.*\(...\)/\1/')"

[ -f "$LOCKFILE" ] && exit

#Check if Working dir exist
if [ ! -d "$WORKINGDIR" ]; then
        echo "Directory $WORKINGDIR does not exist"
    exit 1
fi

touch $LOCKFILE
touch $EMAILFILE

start=`date +%s`

#Random password
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
pass="$({
  choose '!@#$%^\&'
  choose '0123456789'
  choose 'abcdefghijklmnopqrstuvwxyz'
  choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for i in $( seq 1 $(( 4 + RANDOM % 20 )) )
     do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
     done
 } | sort -R | awk '{printf "%s",$1}')"

#increase password length with sha1
pass="$(echo "${pass}$(sha1sum <<< $pass$(date) | awk '{printf "%s",$1}')" | grep -o . | shuf | tr -d "\n")"

cd $WORKINGDIR

#Do System backup
tar -cvp --exclude=$WORKINGDIR --exclude=/proc --exclude=/tmp --exclude=/mnt --exclude=/dev --exclude=/sys --exclude=/run --exclude=/media --exclude=/var/log --exclude=/var/cache/apt/archives --exclude=/var/www/nextcloud/data --exclude=/usr/src/linux-headers* --one-file-system / | gpg --passphrase "$pass" --symmetric --no-tty -o $BACKUPNAME 2>>$LOCKFILE

middle=`date +%s`

#Upload to Mega
megaput -u $megalogin -p $megapass --path /Root/Backup $BACKUPNAME 2>>$LOCKFILE

#delete local old backups
# +15 is older than 15 days
find "$ToFind" -mtime +15 -exec rm {} \; 2>>$LOCKFILE
#find sys*gpg -mtime +15 -exec rm {} \; 2>>$LOCKFILE

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
echo "It took `expr $middle - $start`s to create and `expr $end - $middle`s to upload backup file, or `expr $end - $start`s at all.<$br>" >> $EMAILFILE
echo "Have a nice day and check some statistic.<br>">> $EMAILFILE
echo "<br>">> $EMAILFILE
echo "Backup size: $(du -h $BACKUPNAME | awk '{printf "%s",$1}').<br>" >> $EMAILFILE
echo "SHA256 of backup file: $(sha256sum $BACKUPNAME | awk '{printf "%s",$1}' | tr 'a-z' 'A-Z').<br>" >> $EMAILFILE
echo "<br>">> $EMAILFILE
echo "Space information: $(megadf -u $megalogin -p $megapass -h).<br>" >> $EMAILFILE
[ -s file.name ] && echo "Other info: $(cat $LOCKFILE).<br>" >> $EMAILFILE
#echo "" >> $EMAILFILE

#send email with password
cat $EMAILFILE | /usr/sbin/sendmail $recipients

#remove temporary files
rm $LOCKFILE
rm $EMAILFILE

exit 0
