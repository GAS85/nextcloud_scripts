#!/bin/bash

# By Georgiy Sitnikov.

# Nextcloud Domain without prefix
NextCloudDomain="cloud.domain.net"
# Nextcloud Activity RSS Token only
NextcloudActivityRssToken=""
### OR
# Nextcloud Activity RSS Full URL copied from the Nextcloud
NextCloudActivityRssUrl="https://domain/index.php/apps/activity/rss.php?token=123abc"

# Gotify URL
GotifyDomain="domain.net/gotify"
# Gotify Application Token
GotifyApplicationToken="1234"

LOCKFILE=/tmp/nextcloud-gotify-activity.lock

### END OF CONFIGURATION ###

CentralConfigFile="/etc/nextcloud-scripts-config.conf"

if [[ -f "$CentralConfigFile" ]]; then

	. $CentralConfigFile

fi

curlConfiguration="-fsS -m 10 --retry 5"

if [[ -z "$NextCloudDomain" || -z "$NextcloudActivityRssToken" ]]; then

	# Take RSS Full URL if token and Domain are not defined
	ncRSS="$NextCloudActivityRssUrl"

else

	# Build URL based on Token and Domain
	ncRSS="https://$NextCloudDomain/index.php/apps/activity/rss.php?token=$NextcloudActivityRssToken"

fi

if [[ ! -f "$LOCKFILE" ]]; then

	echo "0" > $LOCKFILE

fi

lastSeen=$(tail -n 1 $LOCKFILE)

# RSS XML Reader as per https://www.linuxjournal.com/content/parsing-rss-news-feed-bash-script

xmlgetnext () {
	local IFS='>'
	read -d '<' TAG VALUE
}

curl $curlConfiguration "$ncRSS" | sed '1!G;h;$!d' | while xmlgetnext ; do
	case $TAG in
		'/item')
			guid=''
			title=''
			link=''
			pubDate=''
			description=''
			;;
		'guid isPermaLink="false"')
			guid="$VALUE"
			;;
		'title')
			title="$VALUE"
			;;
		'link')
			link="$VALUE"
			;;
		'pubDate')
			# convert pubDate format for <time datetime="">
			datetime=$( date --date "$VALUE" --iso-8601=minutes )
			pubDate=$( date --date "$VALUE" '+%d.%m.%Y %X' )
			;;
		'description')
			# convert '&lt;' and '&gt;' to '<' and '>'
			description=$( echo "$VALUE" | sed -e 's/&lt;/</g' -e 's/&gt;/>/g' )
			;;
		'item')

	if [[ "$guid" -gt "$lastSeen" ]]; then

		if [[ ! -z "$description" ]]; then

			message="$description"$'\n'

		fi

		if [[ ! -z "$link" ]]; then

			link="$link"$'\n'

		fi

		# Create Gotify message Body
		message="$description$link""Posted on $pubDate"$'\n'"Nextcloud activity id $guid"

		# Send notification to Gotify
		curl $curlConfiguration -X POST "https://$GotifyDomain/message?token=$GotifyApplicationToken" -F "title=\"$title\"" -F "message=\"$message\"" >> /dev/null

		# Remember last seen message ID from the Nextcloud
		echo $guid > $LOCKFILE

	fi
	;;
	esac
done

exit 0
