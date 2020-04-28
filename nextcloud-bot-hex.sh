#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add hex hex "/usr/local/bin/nextcloud-bot-hex.sh {ARGUMENTS}" 1 3
# More infor under https://nextcloud-talk.readthedocs.io/en/latest/commands/

length=16

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "/hex - A Nextcloud Talk chat wrapper hex to ASCII and backwards"
			echo " "
			echo "Simple execution: /hex 0x21"
			echo "Complex execution: /hex 0x22.0x5a"
			echo ""
			echo "Simple execution: /hex text"
			exit 0
			;;
		*)
	break
	;;
esac
done

# Get first 2 Symbols of variable
first="$(echo $1 | head -c 2)"

if [ "$first" = "0x" ]; then
	#HEX
	# https://stackoverflow.com/questions/13160309/conversion-hex-string-into-ascii-in-bash-command-line
	TESTDATA=$(echo "$1" | tr '.' ' ')
	for c in $TESTDATA; do
		echo $c | xxd -r
	done
	echo
else
	#Text
	echo "$1" | xxd -g 1 -u
fi

exit 0