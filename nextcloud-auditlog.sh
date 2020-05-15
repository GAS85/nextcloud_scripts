#!/bin/bash
 
# By Georgiy Sitnikov.
#
# AS-IS without any warranty

NextCloudPath=/var/www/nextcloud

knownUsersList=

lastMinutes=5

#LogFilePath=/var/www/nextcloud/data/audit.log

tempfile=/tmp/nextcloud_auditlog_$(date +"%M-%N").tmp

show_help () {
echo "This script will fetch data from the Nextclud audit.log and make it Human or Cacti readeble.
Syntax is nextcloud-auditlog.sh.sh -h?Hv <user>

	-h, or ?	for this help
	-H	will generate Human output
	-c	will generate clean uptput with only valid data
	-n	will generate information about non registered users, e.g. CLI User, or user trying to login with wrong name, etc.
	<user>	will generate output only for a particluar user. Default - all users will be fetched from the nextcloud

By Georgiy Sitnikov."
}

fetchLog () {
	awk -v d1=$dateFrom -v d2=$dateTo -F'["]' '$10 > d1 && $10 < d2 || $10 ~ d2' "$LOGFILE" > $tempfile
}

createOutput () {
	echo "Login_$User:$(grep "$User" "$tempfile" | grep "Login" | wc -l)" >> $tempfile.output
	echo "FileAccess_$User:$(grep "$User" $tempfile | grep "File accessed" | wc -l)" >> $tempfile.output
	echo "FileWritten_$User:$(grep "$User" $tempfile | grep "File written" | wc -l)" >> $tempfile.output
	echo "FileCreated_$User:$(grep "$User" $tempfile | grep "File created" | wc -l)" >> $tempfile.output
	echo "FileDeleted_$User:$(grep "$User" $tempfile | grep "was deleted" | wc -l)" >> $tempfile.output
	echo "New_Share_$User:$(grep "$User" $tempfile | grep "has been shared" | wc -l)" >> $tempfile.output
	echo "Share_access_$User:$(grep "$User" $tempfile | grep "has been accessed" | wc -l)" >> $tempfile.output
	echo "Preview_access_$User:$(grep "$User" $tempfile | grep "Preview accessed" | wc -l)" >> $tempfile.output

	cleanOutput
}

cleanOutput () {
	[[ "$clean" = 1 ]] && sed -i '/:0/d' $tempfile.output

	[[ "$human" = 1 ]] && echo "" && echo "For a user $User:" && grep "$User" $tempfile.output | sed 's/user":"--/UnknownUser/g'
}

customUser=$1

while getopts "h?Hcn" opt; do
	case "$opt" in
	help|h|\?)
		show_help
		exit 0
		;;
	H)
		human=1
		customUser=$2
		;;
	c)
		clean=1
		customUser=$2
		;;
	n)
		notUser=1
		customUser='user":"--'
		;;
	esac
done

# Check if config.php exist
[[ -r "$NextCloudPath"/config/config.php ]] || { echo >&2 "Error - config.php could not be read under "$NextCloudPath"/config/config.php. Please check the path and permissions"; exit 1; }

# Fetch data directory place from the config file
DataDirectory=$(grep datadirectory "$NextCloudPath"/config/config.php | cut -d "'" -f4)

if [ "$LogFilePath" = "" ]; then

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

[[ "$human" = 1 ]] && echo "Geting All Users List:"
[[ "$human" = 1 ]] && cat "$tempfile.list"

# Validate User if set
if [ "$customUser" != "" ] && [ "$notUser" = 0 ]; then

	userValidation=$(grep "$customUser" $tempfile.list)

	if [ "$userValidation" = "" ]; then

		echo "User: $customUser not found on Nextcloud"
		exit 1

	else

		[[ "$human" = 1 ]] && echo "$customUser is valid Nextcluod user"

	fi

fi

# Fetch date and time and time shift
getCurrentTimeZone=$(date +"%:::z")

[[ "$human" = 1 ]] && echo "" && echo "Current Time Zone is $getCurrentTimeZone"

getCurrentTimeZone="${getCurrentTimeZone:1}"

timeShiftTo=$((60 * $getCurrentTimeZone))
timeShiftFrom=$((60 * $getCurrentTimeZone + $lastMinutes))

dateFrom=$(date --date="-$timeShiftFrom min" "+%Y-%m-%dT%H:%M:00+00:00")
dateTo=$(date --date="-$timeShiftTo min" "+%Y-%m-%dT%H:%M:00+00:00")

[[ "$human" = 1 ]] && echo "Will evaluate log between $dateFrom and $dateTo"

# Extract logs for a last defined minutes
if [ "$customUser" = "" ]; then

	fetchLog

		while IFS='' read -r User || [[ -n "$User" ]]; do

			createOutput

		done < $tempfile.list

	#allUsers=$(cat $tempfile.list | tr '\n' '|' | sed '$ s/.$//')
	#echo "Login_OTHERS:$(grep -vE "$allUsers" "$tempfile" | grep "Login" | wc -l)" >> $tempfile.output

	User='user":"--'
	createOutput

	#[[ "$human" = 1 ]] && echo "" && echo "For a other users:" && cat $tempfile.output | sed 's/'$User'/UnknownUser/g'

	[[ "$human" = 1 ]] || cat $tempfile.output | tr '\n' ' ' | sed 's/'$User'/UnknownUser/g'

else

		User=$customUser
		fetchLog | grep "$customUser" > $tempfile.output
		createOutput | sed 's/_'$User'//g'

		if [ "$human" != 1 ]; then

			[[ "$notUser" != 1 ]] && cat $tempfile.output | tr '\n' ' ' | sed 's/_'$User'//g'
			[[ "$notUser" = 1 ]] && cat $tempfile.output | tr '\n' ' ' | sed 's/_'$User'/_UnknownUser/g'

		fi

fi

[[ -e "$tempfile" ]] && rm $tempfile
rm $tempfile.list
rm $tempfile.output

exit 0