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
			echo "/time - A Nextcloud Talk chat Timezone wrapper for a https://worldtimeapi.org/timezones API"
			echo " "
			echo "Simple execution: /time"
			echo "will give you current time on the server"
			echo " "
			echo "Complex execution: /time TomeZone"
			echo "E.g: /time Europe/Berlin"
			echo " "
			echo "You can get a full list of timezones via command:"
			echo "/time --list"
			echo " "
			echo "Or added exact Location to search:"
			echo "/time --list Europe"
			exit 0
			;;

		*)

	break

	;;

esac

done

apiCall () {
 
	curl -s -m 5 "http://worldtimeapi.org/api/timezone/"$call | sed 's/,/\n/g' | sed 's/"//g' | sed 's/{\|}//g' | sed 's/\]//g' | sed 's/\[//g' > $temp

	if [ !-z "$(grep "Error" $temp)" ]; then

		echo "Uuups, some error is here. Please try again later."
		echo "For help, please, type /time --help"
		rm $temp
		exit 0

	fi

	if [ "$(cat $temp| head -c5)" = "error" ]; then

		awk -F'[:]' '{ $1 = "Uuups, some error is here: "; print $0 }' $temp
		echo "For help, please, type /time --help"
		rm $temp
		exit 0

	fi

}

# Get first 6 Symbols of variable
first="$(echo $1 | head -c 6)"
rest="$(echo $1 | tail -c +8)"

if [ "$first" = "--list" ]; then

	apiCall

	if [ -z "$rest" ]; then

		echo "Here you can find whole list of Timezones:"
		cat $temp

	else

		echo "Searching for your input in Timezones:"

		if ! grep \"$rest\" $temp; then
			echo "Hmmm, nothing was found"
			echo "Try /time --list to see all Locations, or /time --help for help"
		fi

	fi

	rm $temp
	exit 0

fi

if [ -z "$1" ]; then

	echo "Current local time: $(date +"%Y-%m-%d"), $(date +"%T") $(date +"%Z")"
	exit 0

fi

call=$1
apiCall
 
echo "Current local time in $1: "$(grep datetime $temp | tail -c33 | head -c10), $(grep datetime $temp | tail -c+21 | head -c8) $(grep abbreviation $temp | tail -c+14)""

rm $temp
exit 0
