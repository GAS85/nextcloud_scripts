#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add time time "/usr/local/bin/nextcloud-bot-time.sh {ARGUMENTS}" 1 3
# More infor under https://nextcloud-talk.readthedocs.io/en/latest/commands/

temp="/tmp/nextcloud-bot-time-$(date +"%m-%d-%N")"
while test $# -gt 0; do
	case "$1" in
		--help)
			echo "/time - A Nextcloud Talk chat Timezone wrapper"
			echo " "
			echo "Simple execution: /time"
			echo "will give you current time on the server"
			echo " "
			echo "Complex execution: /time TomeZone"
			echo "E.g: /time Europe/Berlin"
			echo "A full list of timezones can be found here: https://worldtimeapi.org/timezones"
			exit 0
			;;
		*)
	break
	;;
esac
done

if [ -z "$1" ]; then
	echo "Timezone: $(date +"%Z")"
	echo "UTC: $(date +"%:z")"
	echo "Date: $(date +"%Y-%m-%d")"
	echo "Time: $(date +"%T")"
	exit 0
fi

curl -s -m 5 "http://worldtimeapi.org/api/timezone/$1" | sed 's/,/\n/g' | sed 's/"//g' | sed 's/{\|}//g' > $temp

if [ "$(cat $temp| head -c5)" = "error" ]; then
	awk -F'[:]' '{ $1 = "Uuups, some error is here: "; print $0 }' $temp
	exit 0
fi

grep timezone $temp | awk -F'[:]' '{ $1 = "Timezone:"; print $0 }'
grep utc_offset $temp | awk -F'[:]' '{ $1 = "UTC: "; print $1 $2 ":" $3 }'
grep datetime $temp | tail -n 1 | awk -F'[:]' '{ $1 = "Date:"; print $0 }' | head -c16
echo
echo "Time: "$(grep datetime $temp | tail -c22 | head -c8)""

rm $temp

exit 0
