# nextcloud_scripts

for Apache SSL configuration check https://gist.github.com/GAS85/42a5469b32659a0aecc60fa2d4990308

# nextcloud-preview.sh is not needed anymore
since last update, Application will detect if it is aready runned and will not be executed twice/parallel (https://help.nextcloud.com/t/clarity-on-the-crontab-settings-for-the-preview-generator-app/6144/54), so you can added it e.g. to execute each 20 Minutes as cron job directly. This means that nextcloud-preview.sh is not needed anymore, only make sense if you would like to have execution information directly in nextcloud logs.

# nextcloud-usage_report.sh
This script works with https://apps.nextcloud.com/apps/user_usage_report

Will generate report and output it in cacti format
Supports Argument as _"user"_ if you need to check statistic for one user only
run _./nextcloud-usage_report.sh user_ to get specific user information
AS-IS without any warranty

output felds are:

    storage_all, storage_used, shares_new, files_all, files_new, files_read
    
# backupzipper.sh
Will zip and encrypt backup of your MySQL DB and Cacti rrds after that upload it to http://mega.co.nz
MySQL Backup should be done separatly, or uncommented here - it is an option.
Email with password and Cacti graps will be send. Cacti export graphs should be set separatly.  
