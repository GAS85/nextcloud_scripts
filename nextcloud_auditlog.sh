#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty

NextCloudPath=/var/www/nextcloud

knownUsersList=

lastMinutes=5

tempfile=/tmp/nextcloud_auditlog_$(date +"%M-%N").tmp

# Check if config.php exist
[[ -r "$NextCloudPath"/config/config.php ]] || { echo >&2 "Error - config.php could not be read under "$NextCloudPath"/config/config.php. Please check the path and permissions"; exit 1; }

# Fetch data directory place from the config file
DataDirectory=$(grep datadirectory "$NextCloudPath"/config/config.php | cut -d "'" -f4)

# Check if audit.log exist
LogFilePath=$(grep logfile "$NextCloudPath"/config/config.php | cut -d "'" -f4)
if [ LogFilePath = "" ]; then
	LOGFILE=$DataDirectory/audit.log
else
	LOGFILE=$LogFilePath
fi
[[ -r "$LOGFILE" ]] || { echo >&2 "Error - audit.log could not be found under "$LOGFILE"."; exit 1; }

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

# Get All Users List.
php $NextCloudPath/occ user:list | awk -F'[ ]' '{print $4}' | sed 's/://g' > $tempfile.list

# Fetch date and time and time shift
getCurrentTimeZone=$(date +"%:::z")
getCurrentTimeZone="${getCurrentTimeZone:1}"

timeShiftTo=$((60 * $getCurrentTimeZone))
timeShiftFrom=$((60 * $getCurrentTimeZone + $lastMinutes))

dateFrom=$(date --date="-$timeShiftFrom min" "+%Y-%m-%dT%H:%M:00+00:00")
dateTo=$(date --date="-$timeShiftTo min" "+%Y-%m-%dT%H:%M:00+00:00")

# Extract logs for a last defined minutes
awk -v d1="$dateFrom" -v d2="$dateTo" -F'["]' '$10 > d1 && $10 < d2 || $10 ~ d2' "$LOGFILE" > $tempfile

	while IFS='' read -r User || [[ -n "$User" ]]; do

		echo "Login_$User:$(grep "$User" "$tempfile" | grep "Login" | wc -l)" >> $tempfile.output
		echo "FileAccess_$User:$(grep "$User" $tempfile | grep "File accessed" | wc -l)" >> $tempfile.output
		echo "FileWritten_$User:$(grep "$User" $tempfile | grep "File written" | wc -l)" >> $tempfile.output
		echo "FileCreated_$User:$(grep "$User" $tempfile | grep "File created" | wc -l)" >> $tempfile.output
		echo "FileDeleted_$User:$(grep "$User" $tempfile | grep "was deleted" | wc -l)" >> $tempfile.output
		echo "Shared_$User:$(grep "$User" $tempfile | grep "has been shared" | wc -l)" >> $tempfile.output

	done < $tempfile.list
#was deleted
#has been accessed
#Preview accessed

allUsers=$(cat $tempfile.list | tr '\n' '|')
echo "Login_OTHERS:$(grep -vE "$allUsers" "$tempfile" | grep "Login" | wc -l)" >> $tempfile.output

cat $tempfile.output | tr '\n' ' '

rm $tempfile
rm $tempfile.list
rm $tempfile.output

exit 0