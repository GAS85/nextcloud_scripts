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
			echo " "
			echo "A full list of timezones can be found here: https://worldtimeapi.org/timezones"
			exit 0
			;;
		*)
	break
	;;
esac
done

if [ -z "$1" ]; then
	echo "$(date +"%d.%m.%Y"), $(date +"%T") $(date +"%Z")"
	exit 0
fi

curl -s -m 5 "http://worldtimeapi.org/api/timezone/$1" | sed 's/,/\n/g' | sed 's/"//g' | sed 's/{\|}//g' > $temp
 
if [ "$(cat $temp| head -c5)" = "error" ]; then
	awk -F'[:]' '{ $1 = "Uuups, some error is here: "; print $0 }' $temp
	echo "For help, please, type /time --help"
	exit 0
fi

echo "Current local time: "$(grep datetime $temp | tail -c33 | head -c10), $(grep datetime $temp | tail -c+21 | head -c8) $(grep abbreviation $temp | tail -c+14)""


rm $temp

exit 0
