#!/bin/bash

# By Georgiy Sitnikov.

# Nextcloud URL
NEXTCLOUD="cloud.domain.net"
# Nextcloud User
USER=user
# Nextcloud Password
PASSWORD="1234567"

# Gotify URL
GOTIFY="domain.net/gotify"
# Gotify Application Token
TOKEN="1234"

TMPFILE=/tmp/nextcloud-gotify-notifications
LOCKFILE=/tmp/nextcloud-gotify-notifications.lock

. nextcloud-scripts-config.conf

curlConfiguration="-fsS -m 10 --retry 5"

if [ ! -f "$LOCKFILE" ]; then

	touch $LOCKFILE

fi

# Get Nextcloud Notifications
curl $curlConfiguration https://$USER:$PASSWORD@$NEXTCLOUD/ocs/v2.php/apps/notifications/api/v2/notifications | grep -oP "(?<=<notification_id>)[^<]+" | sort > $TMPFILE

lastSeen=$(tail -n 1 $LOCKFILE)

# Stop if last seen message was already seen
if [[ "$(tail -n 1 $TMPFILE)" -le "$lastSeen" ]]; then exit 0; fi

COUNT=0;
for ID in `cat $TMPFILE`; do

	((COUNT++));

	if [[ "$ID" -gt "$lastSeen" ]]; then

		# Get Notification Message from Nextcloud
		curl $curlConfiguration https://$USER:$PASSWORD@$NEXTCLOUD/ocs/v2.php/apps/notifications/api/v2/notifications/$ID | grep -E "<subject>|<message>" | sed '1d' > $TMPFILE

		title=$(grep -oPm1 "(?<=<subject>)[^<]+" $TMPFILE)
		message=$(grep -oPm1 "(?<=<message>)[^<]+" $TMPFILE)

		# Add message body if was not provided as it is required for Gotify
		if [[ "$message" == "" ]]; then message="No message provided"; fi

		# Send notification to Gotify
		curl $curlConfiguration -X POST "https://$GOTIFY/message?token=$TOKEN" -F "title=$title" -F "message=$message" >> /dev/null

		# Remember last seen message ID from the Nextcloud
		echo $ID > $LOCKFILE

	fi

done

# Temp files Cleanup
[[ -f $TMPFILE ]] && { rm $TMPFILE; }

exit 0
