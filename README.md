# nextcloud_scripts

for Apache A+ SSL configuration check https://gist.github.com/GAS85/42a5469b32659a0aecc60fa2d4990308

## Table of content:
- [nextcloud-scripts-config.conf](https://github.com/GAS85/nextcloud_scripts#nextcloud-scripts-configconf)
- [nextcloud-file-sync.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-file-syncsh)
- [nextcloud-preview.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-previewsh)
- [nextcloud-rsync-to-remote.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-rsync-to-remotesh)
- [nextcloud-system-notification.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-system-notificationsh)
- [nextcloud-usage-report.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-usage-reportsh)

### nextcloud-scripts-config.conf
Central configuration file, very handy if you are using more then one script from this banch. Options are:

- Your NC OCC Command path e.g. COMMAND=/var/www/nextcloud/occ
- Your NC log file path e.g. LOGFILE=/var/www/nextcloud/data/nextcloud.log
- Your log file path for other output if needed e.g. CRONLOGFILE=/var/log/next-cron.log
- Your PHP location if different from default e.g. PHP=/usr/bin/php

### nextcloud-file-sync.sh
Basically it works out from the box. Only that you have to check you nextcloud path, log path and create a log file for `php occ` output.
Will do external ONLY shares rescan for nextcloud.

I put it in

    /usr/local/bin/

with `chmod 755`

I run it under _nextcloud user_ (for me it is www-data) basically twice per day at 2:30 and 14:30. You can run it also hourly. This is my cron config:

    30 2,14 * * * perl -e 'sleep int(rand(1800))' && /usr/local/bin/nextcloud-file-sync.sh #Nextcloud file sync

Here I add _perl -e 'sleep int(rand(1800))'_ to inject some random start time within 30 Minutes, but since it scans externals only it is not necessary any more. Your cron job config to run it hourly could be:

    * */1 * * * /usr/local/bin/nextcloud-file-sync.sh

_If you would like to perform WHOLE nextcloud rescan, please add -all to command, e.g.:_

> ./nextcloud-file-sync.sh -all

Lets go through what it does (valid for [commit 44d9d2f](https://github.com/GAS85/nextcloud_scripts/commit/44d9d2ffe1153130560c8039e1299483bc2a36a5)):

> COMMAND=/var/www/nextcloud/occ   **<--  This is where your nextcloud OCC command located**

> OPTIONS="files:scan"   **<--  This is "Command" to run, _just live it as it is_**

> LOCKFILE=/tmp/nextcloud_file_scan   **<--  Lock file to not execute script twice, if already ongoing**

> LOGFILE=/var/www/nextcloud/data/nextcloud.log    **<--  Location of Nextcloud LOG file, will put some logs in Nextcloud format**

> CRONLOGFILE=/var/log/next-cron.log   **<--  location for bash log. In case when there is an output by command generated. AND IT IS GENERATED...**


Line 22 will generate NC log input. You will see it in a GUI as:
![](https://help.nextcloud.com/uploads/default/original/2X/e/ebd7635c409b67d3ee0144246e4ca93f2363540a.png)

From the line 26 starts the job, basically it is left from an older version of script and it is exactly what you done - scan all users, all shares, all locals with all folders. It takes ages to perform an a big installations, so I commented it.

Second option (line 31) is to scan for specific user, but as soon as I get more than one user with external shares it does not work also. Besides it is still scanning whole partition (local and remote) for specific user - commented.

From line 35 till 42 comments how to not forget how I get users from the NC, basically everything is happens in line 45, scipt will generate exactly path for external shares to be updated for all users (you can run it and test output). Here an example command:

    sudo -u www-data php occ files_external:list | awk -F'|' '{print $8"/files"$3}'| tail -n +4 | head -n -1 | awk '{gsub(/ /, "", $0); print}'

and output:

    user1/files/Dropbox-user1
    user2/files/Dropbox-user2
    user1/files/MagentaCloud
    user2/files/MagentaCloud
    user1/files/Local-Folder

Those lines will be read one by one and synced in line 49.

After this script will generate NC log output:
![](https://help.nextcloud.com/uploads/default/original/2X/b/bfc2a6ad6de3d7af5d287776e87ffbcd5d6fcc18.png)

I have had some issues (like described here https://help.nextcloud.com/t/occ-files-cleanup-does-it-delete-the-db-table-entries-of-the-missing-files/20253) in older NC versions, so I added workaround from line 60 till 67 as `files:cleanup` command, nut sure if it is needed now, but it does not harm anything.

### nextcloud-preview.sh
Since last update, Application will detect if it is aready runned and will not be executed twice/parallel (https://help.nextcloud.com/t/clarity-on-the-crontab-settings-for-the-preview-generator-app/6144/54), so you can added it e.g. to execute each 20 Minutes as cron job directly. This means that nextcloud-preview.sh is not needed anymore, _only make sense if you would like to have execution information directly in nextcloud logs_.

This script will generate NC log output:

![](https://help.nextcloud.com/uploads/default/original/2X/7/7a6efcf4700e06457f9bf0eab634eb9f4e012943.png)

### nextcloud-rsync-to-remote.sh

tbd

### nextcloud-system-notification.sh

tbd

### nextcloud-usage-report.sh
This script works with https://apps.nextcloud.com/apps/user_usage_report

Will generate report and output it in cacti format
Supports Argument as _"user"_ if you need to check statistic for one user only
run _./nextcloud-usage_report.sh user_ to get specific user information
AS-IS without any warranty

output felds are:

    storage_all, storage_used, shares_new, files_all, files_new, files_read
    
