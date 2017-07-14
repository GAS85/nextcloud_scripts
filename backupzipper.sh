#!/bin/bash

WORKINGDIR=/media/raid/backups/mysql
LOCKFILE=/tmp/zipping
BACKUPNAME=backup-$(date +"%Y-%m-%d").zip

[ -f "$LOCKFILE" ] && exit

touch $LOCKFILE

#Random password
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
pass="$({ choose '!_@'
  choose '0123456789'
  choose 'abcdefghijklmnopqrstuvwxyz'
  choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for i in $( seq 1 $(( 4 + RANDOM % 16 ))  
     do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
     done
 } | sort -R | awk '{printf "%s",$1}')"
 
#echo $pass

cd $WORKINGDIR
zip --password $pass $BACKUPNAME *.sql.gz

rm $LOCKFILE
exit
