# nextcloud_scripts

----

* for Apache A+ SSL configuration check https://gist.github.com/GAS85/42a5469b32659a0aecc60fa2d4990308
* for Apache HTTP2 enablement check https://gist.github.com/GAS85/8dadbcb3c9a7ecbcb6705530c1252831

----

## Quick overview

* [nextcloud-configuration.conf](#configuration) - Central place for configuration.

----

* [nextcloud-auditlog](#nextcloud-auditlog) - Perform Audit log analyze for a given time and output in cacti format
* [nextcloud-av-notification](#nextcloud-av-notification) - Perform nextcloud log analyze and send notification to any user
* [nextcloud-duplicates-tagger](#nextcloud-duplicates-tagger) - Will find all duplicates in user folder and tag them with any needed tag.
* [nextcloud-file-sync](#nextcloud-file-sync) - Do External Shares rescan only
* [nextcloud-gotify-activity](#nextcloud-gotify-activity) - Read Nextcloud Activity RSS and push updates to Gotify.
* [nextcloud-gotify-notifications](#nextcloud-gotify-notifications) - Read Nextcloud Notifications and push or sync them to Gotify.
* [nextcloud-hardlink-duplicates](#nextcloud-hardlink-duplicates) - Will create hard links to duplicated file together with [rdfind](https://github.com/pauldreik/rdfind).
* [nextcloud-preview](#nextcloud-preview) - Automate preview generation
* [nextcloud-rsync-to-remote](#nextcloud-rsync-to-remote) - Do data Folder rsync to remote via SSH with key Authentication, or into archive
* [nextcloud-system-notification](#nextcloud-system-notification) - Get System Notifications into Nextcloud
* [nextcloud-usage-report](#nextcloud-usage-report) - Generate report in cacti format

----

* [Nextcloud Talk Bots](#nextcloud-talk-bots)
* [nextcloud-bot-links-list](#nextcloud-bot-links-list) - List for a Links Nextcloud Talk bot
* [nextcloud-bot-links](#nextcloud-bot-links) - Links Nextcloud Talk bot
* [nextcloud-bot-rate-1-10](#nextcloud-bot-rate-1-10) - Nextcloud Talk bot to generate simple 1 to 10 rate
* [nextcloud-bot-pass](#nextcloud-bot-pass) - Nextcloud Talk bot to generate random password

## Installation

1. Download
2. Extract
3. Make executable
4. Move to your custom folder
5. Use it

```bash
wget https://git.sitnikov.ga/gas/nextcloud_scripts/archive/master.zip
unzip master.zip
cd nextcloud_scripts
chmod +x *.sh
mv *.sh /usr/local/bin/
mv nextcloud-bot-links-list /usr/local/bin/nextcloud-bot-links-list
mv ./etc/nextcloud-scripts-config.conf /etc/nextcloud-scripts-config.conf
```

Run it under _nextcloud user_ (for me it is www-data).

## Configuration

`nextcloud-scripts-config.conf` is a central configuration file, very handy if you are using more than one script from this bunch. Options are:

* Your NC OCC Command path e.g. `Command=/var/www/nextcloud/occ`
* Your NC log file path e.g. `LogFile=/var/www/nextcloud/data/nextcloud.log`
* Your log file path for other output if needed e.g. `CronLogFile=/var/log/nextvloud-cron.log`
* Your PHP location if different from default e.g. `PHP=/usr/bin/php`

## Scripts

### nextcloud-auditlog

Perform Audit log analyze for a given time and output in cacti format. "Auditing / Logging" App must be enabled.
Example:

```bash
sudo -u www-data /var/www/cacti/scripts/nextcloud_auditlog.sh -n
Login_UnknownUser:6 FileAccess_UnknownUser:0 FileWritten_UnknownUser:0 FileCreated_UnknownUser:0 FileDeleted_UnknownUser:0 New_Share_UnknownUser:0 Share_access_UnknownUser:0 Preview_access_UnknownUser:0
```

```bash
Syntax is nextcloud-auditlog.sh -h?Hv <user>

    -h, or ? for this help
    -H  will generate Human output
    -c  will generate clean output with only valid data
    -n  will generate information about nonregistered users, e.g. CLI User, or user trying to login with wrong name, etc.
    <user> will generate output only for a particular user. Default - all users will be fetched from the nextcloud
```

**TODO** Adjust for common config file and set limit to the users amount.

### nextcloud-av-notification

If you have antivirus installed, then try it. Perform `nextcloud.log` analyze and send notification to any user. Made to avoid [this Issue](https://github.com/nextcloud/files_antivirus/issues/152).

### nextcloud-duplicates-tagger

This script will search all duplicates in user folder and tag them with corresponding tag.
Configuration:

`tagName=duplicate` Tag Name to set on duplicates. Should be exist in system (at least 1 file being tagged with this tag)

`NextcloudURL="https://yourFQDN/nextcloud"` Nextcloud URL to perform API calls

`User="user"` Username

`password="xxxxx-xxxxx-xxxxxx"` Password, please create application password under .../index.php/settings/user/security

`LogLvL=Info` Log Level could be: `none`|`Info`

`NextCloudPath=/var/www/nextcloud` Path to nextcloud Folder. Data folder will be retrieved automatically from the config file.

### nextcloud-file-sync

Performs External Shares re-scan only that will save a lot of time in compare to scan whole nextcloud. Basically, it works out from the box. Only that you must check you nextcloud path, log path and create a log file for `php occ` output.
Will do external ONLY shares re-scan for nextcloud.

Run it under _nextcloud user_ (for me it is www-data) basically twice per day at 2:30 and 14:30. You can run it also hourly. This is my cron config (for more cron examples, please refer to [man pages](http://manpages.ubuntu.com/manpages/focal/en/man5/crontab.5.html)):

```bash
30 2,14 * * * perl -e 'sleep int(rand(1800))' && /usr/local/bin/nextcloud-file-sync.sh #Nextcloud file sync
```

Here I add _perl -e 'sleep int(rand(1800))'_ to inject some random start time within 30 Minutes, but since it scans externals only it is not necessary anymore. Your cron job config to run it hourly could be simple:

```bash
@hourly /usr/local/bin/nextcloud-file-sync.sh
```

_If you would like to perform WHOLE nextcloud re-scan, please add -all to command, e.g.:_

```bash
sudo -u www-data ./nextcloud-file-sync.sh -all
```

Will generate NC log output:
![Nextcloud Log entry example](./img/nextcloud_log.png)

I have had some issues (like described here https://help.nextcloud.com/t/occ-files-cleanup-does-it-delete-the-db-table-entries-of-the-missing-files/20253) in older NC versions, so I added workaround from line 60 till 67 as `files:cleanup` command, nut sure if it is needed now, but it does not harm anything.

### nextcloud-gotify-activity

This script will read Nextcloud Activity RSS via API call and push them to [Gotify server](https://github.com/gotify/server). If you do not see any new activities, try to delete lock file, specified in `LOCKFILE`

Please create Application password for this script.

![Gotify Activity Screenshot](./img/Gotify_activity.png)

### nextcloud-gotify-notifications

This script will read Nextcloud Notifications via API call and push them to [Gotify server](https://github.com/gotify/server). If you do not see any notifications, try to delete lock file, specified in `LOCKFILE`

Please create Application password for this script.

In Gotify Server you have to create an Application and provide API Token to script.

There are 2 modes: `push` and `sync`.

* In case of `push` Notifications from Nextcloud will be pushed to Gotify if you delete notification in Nextcloud or Gotify there will be no reaction.
* In case of `sync` you will have synced notifications stage between both Nextcloud and Gotify, Notification delete in Gotify will cause deletion of this Notification in Nextcloud and opposite.
In Gotify Server you must create a Client Token and provide it to script additionally.

![Gotify Notifications Screenshot](./img/Gotify_notifications.png)

### nextcloud-hardlink-duplicates

In order to reduce HDD space being used, this script will create hardlinks to duplicated files together with [rdfind](https://github.com/pauldreik/rdfind).

### nextcloud-preview

This script avoids parallel Preview Jobs and write execution time to the logs.

Since last update, Application will detect if it is already run and will not be executed [twice/parallel](https://help.nextcloud.com/t/clarity-on-the-crontab-settings-for-the-preview-generator-app/6144/54), so you can add it e.g. to execute each 20 Minutes as cron job directly. **This means that `nextcloud-preview.sh` is not needed anymore**, _only make sense if you would like to have execution information directly in nextcloud logs_.

Will generate NC log output:

![Nextcloud Log output example](./img/nextcloud_log.png)

### nextcloud-rsync-to-remote

This script will do backup of Nextcloud folders via RSYNC to remote machine with SSH Key authentication. You can edit key `--exclude=FolderToExclude` to exclude folders such as:

* `data/appdata*/preview` exclude Previews - they could be newly generated,
* `data/*/files_trashbin/` exclude users trash-bins,
* `data/*/files_versions/` exclude users files Versions,
* `data/updater*` exclude updater backups and downloads,
* `*.ocTransferId*.part` exclude partly uploaded data from backup.

Or you can even combine and do rsync into archive (with remote authentication via SSH Key) if you set `CompressToArchive=true`.

### nextcloud-system-notification

As per [this](https://help.nextcloud.com/t/howto-get-notifications-for-system-updates/10299) tread I added simple script that will do check if updates or reboot is required and show it as NC notification. Works on Ubuntu 16.04+.

![Nextcloud Notification Example](./img/nextcloud_notificaion.png)

You only must specify user from the Administrator group to get notifications via  `USER="admin"`

### nextcloud-usage-report

This script works with https://apps.nextcloud.com/apps/user_usage_report

Will generate report and output it in cacti format. Supports Argument as _"user"_ if you need to check statistic for one user only run `./nextcloud-usage_report.sh user` to get specific user information.
AS-IS without any warranty. Output fields are:

```bash
storage_all, storage_used, shares_new, files_all, files_new, files_read
```

## Nextcloud Talk Bots

### nextcloud-bot-links

This script work as a Talk Chat bot. Will return you useful links specified in `nextcloud-links-list`.
To add bot simply execute:

```bash
sudo -u www-data php /var/www/nextcloud/occ talk:command:add links links "/usr/local/bin/nextcloud-bot-links.sh {ARGUMENTS} {USER}" 2 3
```

More information about is under https://nextcloud-talk.readthedocs.io/en/latest/commands/

In a code, please specify absolute link to the `nextcloud-links-list` as `list`, e.g.:

```bash
list="/usr/local/bin/nextcloud_links_list"
```

Output example:

```bash
/links git
Hey,  here is something useful for you:
Your git is under https://domain/git
```

Known Bug/Feature: it will return all lines with matched words, e.g. if you are typing `/links Your`, you will get whole list from example below.

### nextcloud-bot-links-list

This is a list of useful Links or other Info for a Talk Chat bot. Simply one line per output. E.g.:

```markdown
Your wiki is under https://domain/wiki
Your git is under https://domain/git
Your notes are under https://domain/index.php/apps/notes
```

Basically, you can put in this list whatever to be shown as one line per request.

### nextcloud-bot-rate-1-10

This script work as a Talk Chat bot. Will return you (girls) rate from 1 till 10.
To add bot simply execute:

```bash
sudo -u www-data php /var/www/nextcloud/occ talk:command:add rate rate "/usr/local/bin/nextcloud-bot-rate-1-10.sh {ARGUMENTS}" 2 3
```

More information about is under https://nextcloud-talk.readthedocs.io/en/latest/commands/

Output example:

```bash
/rate
9
```

### nextcloud-bot-pass

This script work as a Talk Chat bot. Will return you random generated 16 (or any length) Characters password.
To add bot simply execute:

```bash
sudo -u www-data php /var/www/nextcloud/occ talk:command:add pass pass "/usr/local/bin/nextcloud-bot-pass.sh {ARGUMENTS}" 1 3
```

Please make sure that you put 1 as `response` argument, this will ensure that only requester can see the output. For more information, please follow https://nextcloud-talk.readthedocs.io/en/latest/commands/

Output example:

```bash
/pass 20
Generated with Urandom
tC1qPQpYJNesjl3BLRFC
Generated with OpenSSL
paRbAxtcU8+w6aN/SBF3
Generated with Bash random
3G5DAqyUeaN!Ewx0HqjO
```
