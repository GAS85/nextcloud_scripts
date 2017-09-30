#!/bin/bash

WORKINGDIR=/media/backup
LOCKFILE=/tmp/zipping
BACKUPNAME=backup-$(date +"%Y-%m-%d").zip
ATTACHDIR=/home/gas/samba/cacti/graphs
recipients="user1@gmail.com,user2@gmail.com,user3@gmail.com"
subject="MySQL backup was done"
from="noreplay@nobody.net"

[ -f "$LOCKFILE" ] && exit

touch $LOCKFILE

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

#zipping with password from above
cd $WORKINGDIR
zip --password $pass $BACKUPNAME *.sql.gz

#Upload to Mega /Backup folder
megaput --no-progress --path /Root/Backup $BACKUPNAME

#send email with password

export ATTACH=$ATTACHDIR/thumb_1.png
export ATTACH1=$ATTACHDIR/thumb_2.png
export ATTACH2=$ATTACHDIR/thumb_3.png
export ATTACH3=$ATTACHDIR/thumb_4.png
export ATTACH4=$ATTACHDIR/thumb_7.png
export ATTACH5=$ATTACHDIR/thumb_8.png
export ATTACH6=$ATTACHDIR/thumb_11.png
export ATTACH7=$ATTACHDIR/thumb_15.png
export ATTACH8=$ATTACHDIR/thumb_18.png
export ATTACH9=$ATTACHDIR/thumb_21.png
export ATTACH10=$ATTACHDIR/thumb_22.png
export BODY="The backup was created with password: $pass Have a nice day and check some statistic."
(
echo "To: $recipients"
echo "FROM: $from"
echo "Subject: $subject"
echo "MIME-Version: 1.0"
echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
echo
echo '---q1w2e3r4t5'
echo "Content-Type: text/html"
echo "Content-Disposition: inline"
echo
echo $BODY
megadf -h
echo
#
# So make man inline file with base64 or uuencode. uuencode will not be read by some programms
#
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH)''
#echo "Content-Transfer-Encoding: uuencode"
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH)''
echo "Content-ID: <$(basename $ATTACH)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH
#uuencode $ATTACH $(basename $ATTACH)
#
# #######################
#
# so make man attachment file with uuencode or base64.
#
#echo '---q1w2e3r4t5'
#echo 'Content-Type: application; name="'$(basename $ATTACH)'"'
#echo "Content-Transfer-Encoding: uuencode"
##echo "Content-Transfer-Encoding: base64"
#echo 'Content-Disposition: attachment; filename="'$(basename $ATTACH)'"'
#echo '---q1w2e3r4t5--'
##base64 $ATTACH
#uuencode $ATTACH $(basename $ATTACH)
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH1)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH1)''
echo "Content-ID: <$(basename $ATTACH1)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH1
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH2)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH2)''
echo "Content-ID: <$(basename $ATTACH2)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH2
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH3)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH3)''
echo "Content-ID: <$(basename $ATTACH3)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH3
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH4)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH4)''
echo "Content-ID: <$(basename $ATTACH4)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH4
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH5)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH5)''
echo "Content-ID: <$(basename $ATTACH5)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH5
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH6)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH6)''
echo "Content-ID: <$(basename $ATTACH6)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH6
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH7)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH7)''
echo "Content-ID: <$(basename $ATTACH7)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH7
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH8)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH8)''
echo "Content-ID: <$(basename $ATTACH8)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH8
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH9)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH9)''
echo "Content-ID: <$(basename $ATTACH9)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH9
echo '---q1w2e3r4t5'
echo 'Content-Type: image/png; name='$(basename $ATTACH10)''
echo "Content-Transfer-Encoding: base64"
echo 'Content-Disposition: inline; filename='$(basename $ATTACH10)''
echo "Content-ID: <$(basename $ATTACH10)>"
echo '---q1w2e3r4t5--'
base64 $ATTACH10
) | /usr/sbin/sendmail $recipients

rm $LOCKFILE
exit
