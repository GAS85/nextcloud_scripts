# nextcloud_scripts

* for Apache A+ SSL configuration check https://gist.github.com/GAS85/42a5469b32659a0aecc60fa2d4990308
* for Apache HTTP2 enablement check https://gist.github.com/GAS85/8dadbcb3c9a7ecbcb6705530c1252831

## Table of content:
- [nextcloud-auditlog.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-file-syncsh#nextcloud-auditlog) - Perform Audit log analyse for a given time and output in cacti format
- [nextcloud-av-notification.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-av-notification) - Perform nextcloud log analyse and send notification to any user
- [nextcloud-file-sync.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-file-syncsh) - Do External Shares rescan only
- [nextcloud-preview.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-previewsh) - Automate preview generation
- [nextcloud-rsync-to-remote.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-rsync-to-remotesh) - Do data Folder rsync to remote via SSH with key Authentication, or into archive
- [nextcloud-scripts-config.conf](https://github.com/GAS85/nextcloud_scripts#nextcloud-scripts-configconf) - Configuration file
- [nextcloud-system-notification.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-system-notificationsh) - Get System Notifications into Nextcloud
- [nextcloud-usage-report.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-usage-reportsh) - Generate report in cacti format
- [Nextcloud Talk Bots](https://github.com/GAS85/nextcloud_scripts#NextcloudTalkBots)
- [nextcloud-bot-links-list](https://github.com/GAS85/nextcloud_scripts#nextcloud-bot-links-list) - List for a Links Nextcloud Talk bot
- [nextcloud-bot-links.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-bot-linkssh) - Links Nextcloud Talk bot
- [nextcloud-bot-rate-1-10.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-bot-rate-1-10sh) - Nextcloud Talk bot to generate simple 1 to 10 rate
- [nextcloud-bot-pass.sh](https://github.com/GAS85/nextcloud_scripts#nextcloud-bot-passsh) - Nextcloud Talk bot to generate random password

---

### nextcloud-scripts-config.conf
Central configuration file, very handy if you are using more then one script from this banch. Options are:

- Your NC OCC Command path e.g. `COMMAND=/var/www/nextcloud/occ`
- Your NC log file path e.g. `LOGFILE=/var/www/nextcloud/data/nextcloud.log`
- Your log file path for other output if needed e.g. `CRONLOGFILE=/var/log/next-cron.log`
- Your PHP location if different from default e.g. `PHP=/usr/bin/php`

---

### nextcloud-auditlog
Perform Audit log analyse for a given time and output in cacti format. "Auditing / Logging" App must be enabled.
Example:

    sudo -u www-data /var/www/cacti/scripts/nextcloud_auditlog.sh -n
    Login_UnknownUser:6 FileAccess_UnknownUser:0 FileWritten_UnknownUser:0 FileCreated_UnknownUser:0 FileDeleted_UnknownUser:0 New_Share_UnknownUser:0 Share_access_UnknownUser:0 Preview_access_UnknownUser:0 

```
Syntax is nextcloud-auditlog.sh.sh -h?Hv <user>

	-h, or ?	for this help
	-H	will generate Human output
	-c	will generate clean uptput with only valid data
	-n	will generate information about non registered users, e.g. CLI User, or user trying to login with wrong name, etc.
	<user>	will generate output only for a particluar user. Default - all users will be fetched from the nextcloud
```

**TODO** Adjust for common config file and set limit to the users amount.

---

### nextcloud-av-notification
Perform nextcloud log analyse and send notification to any user. Made to avoid [this Issue](https://github.com/nextcloud/files_antivirus/issues/152)

---

### nextcloud-file-sync.sh
Basically it works out from the box. Only that you have to check you nextcloud path, log path and create a log file for `php occ` output.
Will do external ONLY shares rescan for nextcloud.

Put it in

    /usr/local/bin/

with `chmod 755`

Run it under _nextcloud user_ (for me it is www-data) basically twice per day at 2:30 and 14:30. You can run it also hourly. This is my cron config (for more cron exampels, plesae refer to [manpages](http://manpages.ubuntu.com/manpages/focal/en/man5/crontab.5.html)):

    30 2,14 * * * perl -e 'sleep int(rand(1800))' && /usr/local/bin/nextcloud-file-sync.sh #Nextcloud file sync

Here I add _perl -e 'sleep int(rand(1800))'_ to inject some random start time within 30 Minutes, but since it scans externals only it is not necessary any more. Your cron job config to run it hourly could be:

    @hourly /usr/local/bin/nextcloud-file-sync.sh

_If you would like to perform WHOLE nextcloud re-scan, please add -all to command, e.g.:_

    ./nextcloud-file-sync.sh -all

Lets go through what it does (valid for [commit 44d9d2f](https://github.com/GAS85/nextcloud_scripts/commit/44d9d2ffe1153130560c8039e1299483bc2a36a5)):

> COMMAND=/var/www/nextcloud/occ   **<--  This is where your nextcloud OCC command located**

> OPTIONS="files:scan"   **<--  This is "Command" to run, _just live it as it is_**

> LOCKFILE=/tmp/nextcloud_file_scan   **<--  Lock file to not execute script twice, if already ongoing**

> LOGFILE=/var/www/nextcloud/data/nextcloud.log    **<--  Location of Nextcloud LOG file, will put some logs in Nextcloud format**

> CRONLOGFILE=/var/log/next-cron.log   **<--  location for bash log. In case when there is an output by command generated. AND IT IS GENERATED...**

Script will generate NC log output:
![](https://help.nextcloud.com/uploads/default/original/2X/b/bfc2a6ad6de3d7af5d287776e87ffbcd5d6fcc18.png)

I have had some issues (like described here https://help.nextcloud.com/t/occ-files-cleanup-does-it-delete-the-db-table-entries-of-the-missing-files/20253) in older NC versions, so I added workaround from line 60 till 67 as `files:cleanup` command, nut sure if it is needed now, but it does not harm anything.

---

### nextcloud-preview.sh
Since last update, Application will detect if it is already run and will not be executed twice/parallel (https://help.nextcloud.com/t/clarity-on-the-crontab-settings-for-the-preview-generator-app/6144/54), so you can added it e.g. to execute each 20 Minutes as cron job directly. This means that nextcloud-preview.sh is not needed anymore, _only make sense if you would like to have execution information directly in nextcloud logs_.

This script will generate NC log output:

![](https://help.nextcloud.com/uploads/default/original/2X/7/7a6efcf4700e06457f9bf0eab634eb9f4e012943.png)

---

### nextcloud-rsync-to-remote.sh
This script will do backup via  RSYNC to remote machine via SSH Key authentication. You can edit key `--exclude=FolderToExclude` to exclude folders such as:
 - `data/appdata*/preview` exclude Previews - they could be newly generated,
 - `data/*/files_trashbin/` exclude users trash-bins,
 - `data/*/files_versions/` exclude users files Versions,
 - `data/updater*` exclude updater backups and downloads,
 - `*.ocTransferId*.part` exclude partly uploaded data from backup.

Or you can even combine and do rsync into archive (with remote authentication via SSH Key) if you set `CompressToArchive=true`

---

### nextcloud-system-notification.sh
As per [this](https://help.nextcloud.com/t/howto-get-notifications-for-system-updates/10299) tread I added simple script that will do check if updates or reboot is required and show it as NC notification. Works on Ubuntu 16.04+.

![](https://help.nextcloud.com/uploads/default/original/2X/9/96a5632b82ecdc46251cc4b42cad8be36086b518.png)

You only have to specify user from the Administrator group to get notifications via  `USER="admin"`

---

### nextcloud-usage-report.sh
This script works with https://apps.nextcloud.com/apps/user_usage_report

Will generate report and output it in cacti format. Supports Argument as _"user"_ if you need to check statistic for one user only run _./nextcloud-usage_report.sh user_ to get specific user information.
AS-IS without any warranty. Output fields are:

    storage_all, storage_used, shares_new, files_all, files_new, files_read

---

## Nextcloud Talk Bots

### nextcloud-bot-links.sh
This script work as a Talk Chat bot. Will return you usefull links specifyed in `nextcloud-links-list`.
To add bot simply execute:

    sudo -u www-data php /var/www/nextcloud/occ talk:command:add links links "/usr/local/bin/nextcloud-bot-links.sh {ARGUMENTS} {USER}" 2 3

More information about is under https://nextcloud-talk.readthedocs.io/en/latest/commands/

In a code, please specify absolute link to the `nextcloud-links-list` as `list`, e.g.:

    list="/usr/local/bin/nextcloud_links_list"

Output example:

    /links git
    Hey,  here is something useful for you:
    Your git is under https://domain/git

Known Bug/Feature: it will return all lines with matched words, e.g. if you are typing `/links Your`, you will get whole list from example below.

### nextcloud-bot-links-list
This is a list of usefull Links or other infor for a Talk Chat bot. Simply one line per output. E.g.:

    Your wiki is under https://domain/wiki
    Your git is under https://domain/git
    Your notes are under https://domain/index.php/apps/notes

Basically you can put in this list whatever to be shown.

### nextcloud-bot-rate-1-10.sh
This script work as a Talk Chat bot. Will return you (girs) rate from 1 till 10.
To add bot simply execute:

    sudo -u www-data php /var/www/nextcloud/occ talk:command:add rate rate "/usr/local/bin/nextcloud-bot-rate-1-10.sh {ARGUMENTS}" 2 3

More information about is under https://nextcloud-talk.readthedocs.io/en/latest/commands/

Output example:

    /rate
    9

### nextcloud-bot-pass.sh
This script work as a Talk Chat bot. Will return you random generated 16 (or any length) Characters password.
To add bot simply execute:

    sudo -u www-data php /var/www/nextcloud/occ talk:command:add pass pass "/usr/local/bin/nextcloud-bot-pass.sh {ARGUMENTS}" 1 3

Please make sure that you put 1 as `response` argument, this will ensure that only requester can see the output. For more information please follow https://nextcloud-talk.readthedocs.io/en/latest/commands/

Output example:

    /pass 20
    Generated with Urandom
    tC1qPQpYJNesjl3BLRFC
    Generated with OpenSSL
    paRbAxtcU8+w6aN/SBF3
    Generated with Bash random
    3G5DAqyUeaN!Ewx0HqjO
