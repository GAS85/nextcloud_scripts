#!/bin/bash

WORKINGDIR=/media/backup
LOCKFILE=/tmp/zipping
BACKUPNAME=backup-$(date +"%Y-%m-%d").zip
recipients="user1@gmail.com,user2@gmail.com,user3@gmail.com"
subject="Backup was done"
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

cd $WORKINGDIR
zip --password $pass $BACKUPNAME *.sql.gz

#send email with password
/usr/sbin/sendmail "$recipients" <<EOF
subject:$subject
from:$from
The backup was created with password: $pass

Have a nice day!
EOF

rm $LOCKFILE
exit
