# nextcloud_scripts

for Apache SSL configuration check https://gist.github.com/GAS85/42a5469b32659a0aecc60fa2d4990308

# nextcloud-preview.sh is not needed anymore
since last update, Application will detect if it is aready runned and will not be executed twice/parallel (https://help.nextcloud.com/t/clarity-on-the-crontab-settings-for-the-preview-generator-app/6144/54), so you can added it e.g. to execute each 20 Minutes as cron job directly. This means that nextcloud-preview.sh is not needed anymore, only make sense if you would like to have execution information directly in nextcloud logs.
