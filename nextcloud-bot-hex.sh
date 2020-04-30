#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add hex hex "/usr/local/bin/nextcloud-bot-hex.sh --hex {ARGUMENTS}" 1 3
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add ascii ascii "/usr/local/bin/nextcloud-bot-hex.sh --ascii {ARGUMENTS}" 1 3
# OR
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add hex hex "/usr/local/bin/nextcloud-bot-hex.sh {ARGUMENTS}" 1 3
# in This case only 1 command will do convertion hex2ascii and ascii2hex
# 
# More infor under https://nextcloud-talk.readthedocs.io/en/latest/commands/

length=16

while test $# -gt 0; do
	case "$1" in
		--help)
			# in case script was added as 1 command via
			# sudo -u www-data php /var/www/nextcloud/occ talk:command:add hex hex "/usr/local/bin/nextcloud-bot-hex.sh {ARGUMENTS}" 1 3
			echo "/hex - A Nextcloud Talk chat wrapper hex to ASCII and backwards"
			echo " "
			echo "Simple execution: /hex 0x21"
			echo "Complex execution: /hex 0x22.0x5a"
			echo "Symbol should start with 0x, Separated by '.' dots, or ' ' spaces."
			echo " "
			echo "Simple execution: /hex text"
			exit 0
			;;

		*)
		case "$2" in
			--help)

				if [ "$1" = "--hex" ]; then
					echo "/hex - A Nextcloud Talk chat wrapper hex to ASCII"
					echo " "
					echo "for ASCII to hex see /ascii"
					echo " "
					echo "Simple execution: /hex 0x21"
					echo "Complex execution: /hex 0x22.0x5a"
					echo "First Symbol should start with 0x, Separated by '.' dots, or ' ' spaces"
					exit 0
				fi

				if [ "$1" = "--ascii" ]; then
					echo "/ascii - A Nextcloud Talk chat wrapper ASCII to hex"
					echo " "
					echo "for hex to ASCII see /hex"
					echo " "
					echo "Simple execution: /ascii Letter"
					echo "Simple execution: /ascii Some Text"
					exit 0
				fi
				;;

			*)
			break
			;;
		esac
	esac
done

hex2ascii () {

	echo "$userInput"
	echo "$userInput" | xxd -r
	echo
	exit 0

}

ascii2hex () {

	echo "$userInput" | xxd -g 1 -u
	echo
	exit 0

}

if [ "$1" = "--hex" ]; then

	# Get first 2 Symbols of variable
	first="$(echo $2 | head -c 2)"

	if [ "$first" = "0x" ]; then

		userInput="$2"

	else

		userInput="0x$2"

	fi

	hex2ascii

fi

if [ "$1" = "--ascii" ]; then

	userInput="$2"
	ascii2hex

fi

# in case script was added as 1 command via
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add hex hex "/usr/local/bin/nextcloud-bot-hex.sh {ARGUMENTS}" 1 3

# Get first 2 Symbols of variable
first="$(echo $1 | head -c 2)"

if [ "$first" = "0x" ]; then

	userInput=$(echo "$@" | tr '.' ' ')
	hex2ascii

else

	userInput="$@"
	ascii2hex

fi

exit 0
