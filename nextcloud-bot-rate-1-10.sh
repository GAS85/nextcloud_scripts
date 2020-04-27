#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty
#
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add rate rate "/usr/local/bin/nextcloud-bot-rate-1-10.sh {ARGUMENTS}" 2 3
#
# More infor under https://nextcloud-talk.readthedocs.io/en/latest/commands/

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "/rate - A Nextcloud Talk chat wrapper for simple rate from 1 to 10"
			echo " "
			echo "Simple execution: /rate"
			exit 0
			;;
		*)
	break
	;;
esac
done

echo $((1 + RANDOM % 10))

exit 0
