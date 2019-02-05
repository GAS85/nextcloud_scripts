#!/bin/bash

# By Georgiy Sitnikov.
#
# Will do NC backup and it upload to remote server via SSH with key authentication
#
# AS-IS without any warranty

SSHIdentityFile=/path/to/file/.ssh/id_rsa
SSHUser=user
RemoteAddr=IP_or_host
RemoteBackupFolder=/path/to/backup
NextCloudPath=/var/www/nextcloud

# Folder and files to be excluded from backup.
# - data/updater* exclude updater backups and dowloads 
# - *.ocTransferId*.part exclude partly uploaded files
#
# This is reasonable "must have", everything below is just to save place:
#
# - data/appdata*/preview exclude Previews - they could be newle generated
# - data/*/files_trashbin/ exclude users trashbins
# - data/*/files_versions/ exclude users files Versions

excludeFromBackup="--exclude=data/updater*\
 --exclude=*.ocTransferId*.part\
 --exclude=data/appdata*/preview"

# Compress to needs to have archivemount and sshfs installed.
CompressToArchive=false
WhereToMount=/mnt/remoteSystem # Needs to be set if CompressToArchive is true
RemoteArchiveName=backup.tar.gz # Needs to be set if CompressToArchive is true

##############################################################################

InstallerCheck () {
	# Check if all Programms are installed
	hash $1 2>/dev/null || { echo >&2 "It requires $1 but it's not installed. Aborting."; exit 1; }
}

# Check if config.php exist
[[ -e $NextCloudPath/config/config.php ]] || { echo >&2 "Error - сonfig.php could not be found under "$NextCloudPath"/config/config.php. Please check the path"; exit 1; }

# Fetch data directory place from the config file
DataDirectory=$(grep datadirectory $NextCloudPath/config/config.php | cut -d "'" -f4)

RsyncOptions="-a --partial --info=progress2 --no-o --no-g --delete"
#RsyncOptions="-aP --info=progress2 --no-o --no-g --delete"

InstallerCheck rsync

if [ "$CompressToArchive" == true ]; then

	InstallerCheck sshfs
	InstallerCheck archivemount

	RsyncOptions="-aP --delete"

	mkdir -p $WhereToMount;
	mkdir -p $WhereToMount_$(date);

	echo Mount remote system
	sshfs -o allow_other,default_permissions,IdentityFile=$SSHIdentityFile $SSHUser@$RemoteAddr:$RemoteBackupFolder:$RemoteBackupFolder $WhereToMount

	sleep 2

	if [ -f "$WhereToMount/$RemoteArchiveName" ]; then

		echo Mount remote Archive
		archivemount $WhereToMount/$RemoteArchiveName $WhereToMount_$(date)

		echo Rsync of NC into Archive
		rsync $RsyncOptions $excludeFromBackup $NextCloudPath $WhereToMount_$(date)

		echo Wait to finish sync
		sleep 5

		echo Unmount Archive
		umount $WhereToMount_$(date)

	else

		InstallerCheck tar

		echo Put NC into Archive
		echo "Will create Archive under $WhereToMount"
		echo "With name nextcloudBackup-$(date +"%Y-%m-%d_%T")_$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 ).tar.gz"

		tar -cvpf $excludeFromBackup --one-file-system $NextCloudPath $WhereToMount/nextcloudBackup-$(date +"%Y-%m-%d_%T")_$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 ).tar.gz

	fi

	echo Wait to finish sync
	sleep 5

	echo Unmount Remote FS
	umount $WhereToMount

else

	echo Run Rsync of NC root folder.
	rsync $RsyncOptions --exclude=data --exclude=$DataDirectory -e "ssh -i $SSHIdentityFile" $NextCloudPath $SSHUser@$RemoteAddr:$RemoteBackupFolder/nextcloud/

	echo Run Rsync of NC Data folder (found under $DataDirectory).
	rsync $RsyncOptions $excludeFromBackup -e "ssh -i $SSHIdentityFile" $DataDirectory $SSHUser@$RemoteAddr:$RemoteBackupFolder/nextcloud/

fi

echo Ready.

exit 0
