#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty

# Administrator User to notify
USER="admin"

NextCloudPath=/var/www/nextcloud

lastMinutes=30

###

tempfile=/tmp/nextcloud_av_notofications-$(date +"%M-%N").tmp

# Check if config.php exist
[[ -r "$NextCloudPath"/config/config.php ]] || { echo >&2 "Error - config.php could not be read under "$NextCloudPath"/config/config.php. Please check the path and permissions"; exit 1; }

# Fetch data directory place from the config file
DataDirectory=$(grep datadirectory "$NextCloudPath"/config/config.php | cut -d "'" -f4)

# Check if audit.log exist
LogFilePath=$(grep logfile "$NextCloudPath"/config/config.php | cut -d "'" -f4)
if [ LogFilePath = "" ]; then
	LOGFILE=$DataDirectory/nextcloud.log
else
	LOGFILE=$LogFilePath
fi
[[ -r "$LOGFILE" ]] || { echo >&2 "Error - nextcloud.log could not be found under "$LOGFILE"."; exit 1; }

# Check if OCC is reacheble
if [ ! -w "$NextCloudPath/occ" ]; then
	echo "ERROR - Command $NextCloudPath/occ not found. Make sure taht path is corrct."
	exit 1
else
	if [ "$EUID" -ne "$(stat -c %u $NextCloudPath/occ)" ]; then
		echo "ERROR - Command $NextCloudPath/occ not executable for current user.
	Make sure that user has right to execute it.
	Script must be executed as $(stat -c %U $NextCloudPath/occ)."
		exit 1
	fi
fi

# Fetch date and time and time shift
getCurrentTimeZone=$(date +"%:::z")
getCurrentTimeZone="${getCurrentTimeZone:1}"

timeShiftTo=$((60 * $getCurrentTimeZone))
timeShiftFrom=$((60 * $getCurrentTimeZone + $lastMinutes))

dateFrom=$(date --date="-$timeShiftFrom min" "+%Y-%m-%dT%H:%M:00+00:00")
dateTo=$(date --date="-$timeShiftTo min" "+%Y-%m-%dT%H:%M:00+00:00")

# Extract logs for a last defined minutes
awk -v d1="$dateFrom" -v d2="$dateTo" -F'["]' '$10 > d1 && $10 < d2 || $10 ~ d2' "$LOGFILE" | grep "Infected file" | awk -F'["]' '{print $34}' > $tempfile

if [ ! -s "$tempfile" ]; then

	# Extract logs for a last defined minutes, from a ROTATED log if present
	if [ "$(find "$LOGFILE.1" -mmin -"$lastMinutes")" != "" ]; then

		awk -v d1="$dateFrom" -v d2="$dateTo" -F'["]' '$10 > d1 && $10 < d2 || $10 ~ d2' "$LOGFILE.1" | grep "Infected file" | awk -F'["]' '{print $34}' >> $tempfile

	fi

	# Exit if no results found
	[[ -s "$tempfile" ]] || { rm $tempfile; exit 0; }

fi

generateNotification () {

	php $NextCloudPath/occ notification:generate $USER "Infected File(s) $toFind!" -l "$(cat $tempfile.output | cut -c -4000)"
#	cat $tempfile.output | cut -c -4000

}

preparingOutput () {

	if [ "$(grep "$toFind" "$tempfile" | wc -l)" -gt 0 ]; then

		#grep "$toFind" "$tempfile" | awk '{$1=""; $2 = ""; $3 = "";$4 = ""; $5 = ""; $6 = ""; print $0}' | awk -F'[/]' '{$1 = ""; $2 = ""; $3 = ""; print $0}' | sed 's/   //g' > $tempfile.output
		grep "$toFind" "$tempfile" | awk '{$1=""; $2 = ""; $3 = "";$4 = ""; $5 = ""; $6 = ""; print $0}' | sed -r -e 's/appdata_.{12}//' | sed 's/   //g' > $tempfile.output

		generateNotification

	fi
}

toFind="found"
preparingOutput

toFind="deleted"
preparingOutput

rm $tempfile
rm $tempfile.output

exit 0
