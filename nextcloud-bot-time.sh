#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add time time "/usr/local/bin/nextcloud-bot-time.sh {ARGUMENTS}" 1 3
# More infor under https://nextcloud-talk.readthedocs.io/en/latest/commands/

maxDelay=5

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
 
	if [ -z "$call" ]; then

		curl -s -m $maxDelay "http://worldtimeapi.org/api/timezone.txt" > $temp

	else

		curl -s -m $maxDelay "http://worldtimeapi.org/api/timezone/"$call.txt > $temp

	fi

}

APInewTry () {

	newTry=$call
	call=""
	apiCall
	call=$(grep "$newTry" $temp | head -n 1)

	if [ ! -z "$call" ]; then

		echo "Did you mean $call?"
		apiCall
		echo "Current local time in $call: "$(grep datetime $temp | tail -c33 | head -c10), $(grep datetime $temp | tail -c+21 | head -c8) $(grep abbreviation $temp | tail -c+14)

	fi

}

checkForErrors () {

	if [ "$(cat $temp| head -c 5)" = "Error" ]; then

		awk '{ $1 = "Uuups, some error is here:"; print $0 }' $temp

		APInewTry

		echo " "
		echo "For help, please, type /time --help"
		rm $temp
		exit 0

	fi

	# Added check if List returned
	if [ "$(grep datetime $temp | tail -c33 | head -c10)" = "" ] && [ "$first" != "--list" ]; then

		APInewTry
		rm $temp
		exit 0

	fi

}

# Get first 6 Symbols of variable
first="$(echo $1 | head -c 6)"
rest="$(echo $1 | tail -c +8)"

#Added input Validator
#https://stackoverflow.com/questions/36926999/removing-all-special-characters-from-a-string-in-bash
validInput="$(echo "$rest" | sed 's/[^a-z A-Z 0-9]//g')"
if [ "$validInput" = "" ] && [ ! -z "$rest" ]; then
	echo "Seems you use only Special Characters, currently only a-z, A-Z and digits are supported"
	exit 0
fi

if [ "$first" = "--list" ]; then

	apiCall
	checkForErrors

	if [ -z "$validInput" ]; then

		echo "Here you can find whole list of Timezones:"
		cat $temp

	else

		echo "Searching for your input in Timezones:"

		#Check if multiple words are separated by spaces
		case "$validInput" in

			*\ * )

				multipleInput=$(echo "$validInput" | tr ' ' '|')
				#will display exact mutliple match, or an error message
				if ! grep -E "$multipleInput" "$temp"; then

					echo "Hmmm, nothing was found"
					echo "Try /time --list to see all Locations, or /time --help for help"

				fi

			;;

			*)

				#will display exact match, or an error message
				if ! grep "$validInput" "$temp"; then

					echo "Hmmm, nothing was found"
					echo "Try /time --list to see all Locations, or /time --help for help"

				fi

			;;
		esac

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
checkForErrors

echo "Current local time in $1: "$(grep datetime $temp | tail -c33 | head -c10), $(grep datetime $temp | tail -c+21 | head -c8) $(grep abbreviation $temp | tail -c+14)

rm $temp
exit 0
