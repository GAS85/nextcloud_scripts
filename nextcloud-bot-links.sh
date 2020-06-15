#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add links links "/usr/local/bin/nextcloud_links.sh {ARGUMENTS} {USER}" 2 3
# More info under https://nextcloud-talk.readthedocs.io/en/latest/commands/

list="/usr/local/bin/nextcloud-bot-links-list"

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "/links - A Nextcloud Talk chat wrapper for important links"
			echo " "
			echo "Simple execution: /links"
			echo "Complex execution: /links wiki git"
			exit 0
			;;
		*)
	break
	;;
esac
done

#Added input Validator
#https://stackoverflow.com/questions/36926999/removing-all-special-characters-from-a-string-in-bash
validInput="$(echo "$1" | sed 's/[^a-z  A-Z 0-9]//g')"
if [ "$validInput" = "" ] && [ ! -z "$1" ]; then
	echo "Seems you use only Special Characters, currently only a-z, A-Z and digits are supported"
	exit 0
fi

echo "Hey, "$2" here is something useful for you:"
if [ "$validInput" = "" ]; then
	#will display whole list because nothing specifyed
	cat "$list"
else
	#Check if multiple words are separated by spaces
	case "$validInput" in
		*\ * )
			multipleInput=$(echo "$validInput" | tr ' ' '|')
			#will display exact mutliple match, or an error message
			if ! grep -E "$multipleInput" "$list"; then
				echo "Hmmm, nothing was found"
			fi
		;;
		*)
			#will display exact match, or an error message
			if ! grep "$validInput" "$list"; then
				echo "Hmmm, nothing was found"
			fi
		;;
	esac
fi

exit 0