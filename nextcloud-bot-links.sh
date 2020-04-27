#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty
# 
# To added to Nextcloud please execute:
# sudo -u www-data php /var/www/nextcloud/occ talk:command:add links links "/usr/local/bin/nextcloud_links.sh {ARGUMENTS} {ROOM} {USER}" 2 3
# More infor under https://nextcloud-talk.readthedocs.io/en/latest/commands/

list="/usr/local/bin/nextcloud_links_list"

while test $# -gt 0; do
	case "$1" in
		--help)
			echo "/links - A Nextcloud Talk chat wrapper for important links"
			echo " "
			echo "Simple execution: /links"
			echo "Complex execution: /links wiki"
			exit 0
			;;
		*)
	break
	;;
esac
done

echo "Hey, "$3" here is something useful for you:"
if [ "$1" = "" ]; then
	#will display whole list because nothing specifyed
	cat $list
else
	#will display exact match, or an error message
	if ! grep "$1" $list; then
		echo "Hmmm, nothing was found"
	fi
fi

exit 0
