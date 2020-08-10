#!/bin/bash

# By Georgiy Sitnikov.
#
# AS-IS without any warranty

# Will search and tag all Duplicated files by user.

tagName=duplicate

NextcloudURL="https://yourFQDN/nextcloud"
user="user"
password="xxxxx-xxxxx-xxxxxx"

# Log Level: none|Info
LogLvL=Info

# Path to nextcloud
NextCloudPath=/var/www/nextcloud

#####################
### End of Config ###
#####################

LOCKFILE=/tmp/nextcloud-duplicates-tagger.tmp

# Check if config.php exist
[[ -r "$NextCloudPath"/config/config.php ]] || { echo >&2 "[ERROR] config.php could not be read under "$NextCloudPath"/config/config.php. Please check the path and permissions"; exit 1; }

# Fetch data directory place from the config file
DataDirectory=$(grep datadirectory "$NextCloudPath"/config/config.php | cut -d "'" -f4)

# Check if user Derectory exist
[[ -d "$DataDirectory/$user" ]] || { echo >&2 "[ERROR] User "$user" could not be found. Please check if case is correct"; exit 1; }

getFileID () {

	fileid="$(curl -s -m 10 -u $user:$password ''$NextcloudURL'/remote.php/dav/files/'${user}'/'${fileToTag}'' \
-X PROPFIND --data '<?xml version="1.0" encoding="UTF-8"?>
 <d:propfind xmlns:d="DAV:">
   <d:prop xmlns:oc="http://owncloud.org/ns">
     <oc:fileid/>
   </d:prop>
 </d:propfind>' | xml_pp | grep "fileid" | sed -n 's/^.*<\(oc:fileid\)>\([^<]*\)<\/.*$/\2/p')"

	[[ "$LogLvL" == "Info" ]] && { echo "[INFO] Searching Nextcloud Internal FileID for $fileToTag"; }

	if [[ -z "$fileid" ]]; then

		echo "[WARNING] File ID could not be found for a "$fileToTag" will skip it."
		#exit 1

	else

		[[ "$LogLvL" == "Info" ]] && { echo "[INFO] FileID is $fileid."; }

	fi

}

getTag () {

	getAllTags="$(curl -s -m 10 -u $user:$password ''$NextcloudURL'/remote.php/dav/systemtags/' \
-X PROPFIND --data '<?xml version="1.0" ?>
<d:propfind  xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
  <d:prop>
    <oc:id />
    <oc:display-name />
    <oc:user-visible />
    <oc:user-assignable />
    <oc:can-assign />
  </d:prop>
</d:propfind>' | xml_pp | grep -B 1 -w "$tagName" | head -n 1)"

	if [[ ! -z "$getAllTags" ]]; then

		tagID="$(echo $getAllTags | sed -n 's/^.*<\(oc:id\)>\([^<]*\)<\/.*$/\2/p')"
		[[ "$LogLvL" == "Info" ]] && { echo "[INFO] Internal TagID for tag $tagName is $tagID."; }

	else

		echo "[ERROR] Could to find tagID for a tag $tagName. Please check spelling and if tag exist"
		exit 1

	fi

}

SetTag () {

	curl -s -m 10 -u $user:$password ''$NextcloudURL'/remote.php/dav/systemtags-relations/files/'$fileid/$tagID \
-X PUT -H "Content-Type: application/json" \
--data '{"userVisible":true,\
"userAssignable":true,\
"canAssign":true,\
"id":"'$tag'",\
"name":"'$tagName'"}'
	echo "[PROGRESS] Setting tag $tagName for $fileToTag."

}

checkIfTagIsSet () {

	if [[ -z "$fileid" ]]; then

		getAllTags="$(curl -s -m 10 -u $user:$password ''$NextcloudURL'/remote.php/dav/systemtags-relations/files/'$fileid'' \
-X PROPFIND --data '<?xml version="1.0" ?>
<d:propfind  xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
  <d:prop>
    <oc:id />
    <oc:display-name />
    <oc:user-visible />
    <oc:user-assignable />
    <oc:can-assign />
  </d:prop>
</d:propfind>' | xml_pp | grep -w "$tagName")"

		if [[ ! -z "$getAllTags" ]]; then

			[[ "$LogLvL" == "Info" ]] && { echo "[INFO] Tag $tagName is already set for $fileToTag, skipping."; }

		else

			#echo "[INFO] Tag $tagName is not set"
			SetTag

		fi

	fi

}

findDuplicates () {

	echo "[PROGRESS] Searching for duplicates, this can take a long time..."
	cd $DataDirectory/$user/files/

	find . ! -empty -type f -exec md5sum {} + | sort | uniq -w32 -dD >> $LOCKFILE
	[[ "$LogLvL" == "Info" ]] && { echo "[INFO] Finally finisched it is $(wc -l $LOCKFILE | awk '{print $1}') duplicates found"; }

}

checkLockFile () {

	if [ -f "$LOCKFILE" ]; then

		# Remove lock file if script fails last time and did not run more then 10 days due to lock file.
		echo "[WARNING] - An older Duplicates report found in a $LOCKFILE,
            will use it to tag files, it contains $(wc -l $LOCKFILE | awk '{print $1}') duplicates.
            If you want to perform new search, please delete this file under: $LOCKFILE
            e.g. execute: rm $LOCKFILE

            File will be automatically deleted if older than 10 days.
"
		find "$LOCKFILE" -mtime +10 -type f -delete
		#exit 1

	fi

	touch $LOCKFILE

}

# From https://gist.github.com/cdown/1163649
urlencode() {

	local LANG=C i c e=''

	for ((i=0;i<${#1};i++)); do

		c=${1:$i:1}
		[[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
		e+="$c"

	done

	# sed here will return slashes back to the path
	echo "$e" | sed 's/%2F/\//g'

}

# From https://gist.github.com/cdown/1163649
urldecode() {

	# urldecode <string>

	local url_encoded="${1//+/ }"
	printf '%b' "${url_encoded//%/\\x}"

}

fileToTagPath() {

	urlencode "$(echo $line | cut -c 36-)"

}

checkLockFile

getTag

# Will use existing Tag report
[[ -s "$LOCKFILE" ]] || { findDuplicates; }

while read line; do

	# reading each line

	fileToTag=$(fileToTagPath)

	getFileID

	checkIfTagIsSet

done < $LOCKFILE

#rm $LOCKFILE

exit 0
