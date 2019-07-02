#!/bin/bash
#Tableau Server on Linux Backup Script

# Variables:
# Grab the current datetime for timestamping the log entries
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
# How many days do you want to keep old backup files for? 
backup_days="1"
# What do you want to name your backup files? (will automatically append current date to this filename)
backup_name="tableau-server-backup"

# Input
# Get tsm username from command line input
tsmuser=$1
# Get tsm password from command line input
tsmpassword=$2 

# Enviroment:
# Load the Tableau Server environment variables into the cron environment
source /etc/profile.d/tableau_server.sh
# In case that doesn't work then this might do it 
load_environment_file() {
  if [[ -f /etc/opt/tableau/tableau_server/environment.bash ]]; then
    source /etc/opt/tableau/tableau_server/environment.bash
    env_file_exists=1
  fi
}

# Backup
# get the path to the backups folder
backup_path=$(tsm configuration get -k basefilepath.backuprestore -u $tsmuser -p $tsmpassword)
echo $TIMESTAMP "The path for storing backups is $backup_path" 

# count the number of backup files eligible for deletion and output 
echo $TIMESTAMP "Cleaning up old backups..."
lines=$(find $backup_path -type f -name '*.tsbak' -mtime +$backup_days | wc -l)
if [ $lines -eq 0 ]; then 
	echo $TIMESTAMP $lines old backups found, skipping...
	else $TIMESTAMP $lines old backups found, deleting...
		#remove backup files older than N days
		find $backup_path -type f -name '*.tsbak' -mtime +$backup_days -exec rm {} \;
fi

#export current settings
echo $TIMESTAMP "Exporting current settings..."
tsm settings export -f $backup_path/settings.json -u $tsmuser -p $tsmpassword

#create current backup
echo $TIMESTAMP "Backup up Tableau Server data..."
tsm maintenance backup -f $backup_name -d -u $tsmuser -p $tsmpassword

echo $TIMESTAMP "Backup completed"