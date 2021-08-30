#!/bin/bash

# By Georgiy Sitnikov.

# Nextcloud Domain without prefix
NextCloudDomain="cloud.domain.net"
# Nextcloud User
NextCloudUser=user
# Nextcloud Password
NextCloudPassword="1234567"

# Gotify URL
GotifyDomain="domain.net/gotify"
# Gotify Application Token
GotifyApplicationToken="1234"
# Gotify Application ID
GotifyApplicationId=4
# Gotify Client Token
GotifyClientToken="56789"

# Mode could be "push" and "sync". In case of sync you, have to create and provide Gotify Client Token.
NotificationsSyncMode=push
#NotificationsSyncMode=sync

TMPFILE=/tmp/nextcloud-gotify-notifications
LOCKFILE=/tmp/nextcloud-gotify-notifications.lock

CentralConfigFile="/etc/nextcloud-scripts-config.conf"

if [ -f "$CentralConfigFile" ]; then

	. $CentralConfigFile

fi

### END OF CONFIGURATION ###

# Set Nextcloud API URL
ncAPI="https://$NextCloudUser:$NextCloudPassword@$NextCloudDomain/ocs/v2.php/apps/notifications/api/v2/notifications"

curlConfiguration="-fsS -m 10 --retry 5"

if [ ! -f "$LOCKFILE" ]; then

	echo "0" > $LOCKFILE

fi

# Collect Nextcloud Notifications IDs
curl $curlConfiguration "$ncAPI" | grep -oP "(?<=<notification_id>)[^<]+" | sort > $TMPFILE.next

lastSeen=$(tail -n 1 $LOCKFILE)

# Push Notifications to Gotify
if [[ "$(tail -n 1 $TMPFILE.next)" -ge "$lastSeen" ]]; then

	COUNT=0;
	for ID in `cat $TMPFILE.next`; do

		((COUNT++));

		if [[ "$ID" -gt "$lastSeen" ]]; then

			# Get particular Notification Message from Nextcloud
			curl $curlConfiguration "$ncAPI/$ID" | grep -E "<subject>|<message>" | sed '1d' > $LOCKFILE

			title=$(grep -oPm1 "(?<=<subject>)[^<]+" $LOCKFILE)
			message=$(grep -oPm1 "(?<=<message>)[^<]+" $LOCKFILE)

			# Add message body if was not provided as it is required for Gotify
			if [[ "$message" == "" ]]; then

				message="Nextcloud notification id $ID"

			else

				message="$message"$'\n'"Nextcloud notification id $ID"

			fi

			# Send notification to Gotify
			curl $curlConfiguration -X POST "https://$GotifyDomain/message?token=$GotifyApplicationToken" -F "title=$title" -F "message=$message" >> /dev/null

			# Remember last seen message ID from the Nextcloud
			echo $ID > $LOCKFILE

		fi

	done

fi

if [[ "$NotificationsSyncMode" == "sync"  ]]; then

	# Collect Nextcloud Notifications IDs pushed to Gotify
	curl $curlConfiguration "https://$GotifyDomain/application/$GotifyApplicationId/message?token=$GotifyClientToken" | grep -oP "Nextcloud notification id\s+\K\w+" | sort | uniq > $TMPFILE.got

	# Compare Notification ID in Gotify and Nextcloud
	cat $TMPFILE.next $TMPFILE.got | sort | uniq -u > $TMPFILE.uniq

	# Stop if no difference was found
	[ -s $TMPFILE.uniq ] || exit 0

	# Delete Notifications from Nextcloud if it was deleted in Gotify
	COUNT=0;
	for ID in `cat $TMPFILE.uniq`; do

		((COUNT++));

		# Check if message is still in Nextcloud before to delete it
		if [[ ! -z "$(cat $TMPFILE.next $TMPFILE.uniq | sort | uniq -d)" ]]; then

			curl $curlConfiguration -H "OCS-APIREQUEST: true" -X DELETE "$ncAPI/$ID" >> /dev/null

		fi

	done

	# Get all Gotify Notifications IDs related to Nextcloud
	curl $curlConfiguration "https://$GotifyDomain/application/$GotifyApplicationId/message?token=$GotifyClientToken" | json_pp | grep -E '"id" : |Nextcloud notification id' | grep -B 1 "Nextcloud notification id" > $TMPFILE.got

	# Delete Notifications from Gotify if it was deleted in Nextcloud
	COUNT=0;
	for ID in `cat $TMPFILE.uniq`; do

		((COUNT++));
		# Get corresponding Gotify Notification ID
		toDelete=$(grep -B 1 "Nextcloud notification id $ID" $TMPFILE.got | grep -oP '"id" :\s+\K\w+' | head -n 1)

		if [[ ! -z "$toDelete" ]]; then

			curl $curlConfiguration -X DELETE "https://$GotifyDomain/message/$toDelete" -H "X-Gotify-Key:$GotifyClientToken" >> /dev/null

		fi

	done

fi

# Temp files Cleanup
[[ -f $TMPFILE.next ]] && { rm $TMPFILE.next; }
[[ -f $TMPFILE.got ]] && { rm $TMPFILE.got; }
[[ -f $TMPFILE.uniq ]] && { rm $TMPFILE.uniq; }

exit 0
