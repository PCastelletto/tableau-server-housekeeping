#!/bin/bash
#Tableau Server on Linux Logs and Cleanup Script

# Variables:
# Grab the current date in YYYY-MM-DD format
DATE=`date +%Y-%m-%d`
# How many days to you want to keep archived log files for?
log_days="2"
# What do you want to name your logs file? (will automatically append current date to this filename)
log_name="logs"

# Input:
# Get tsm username from command line
tsmuser=$1
# Get tsm password from command line
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

# Clean Logs
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
log_path=$(tsm configuration get -k basefilepath.log_archive -u $tsmuser -p $tsmpassword)
echo $TIMESTAMP "The path for storing log archives is $log_path" 

# count the number of log files eligible for deletion and output 
echo $TIMESTAMP "Cleaning up old log files..."
lines=$(find $log_path -type f -name '*.zip' -mtime +$log_days | wc -l)
if [ $lines -eq 0 ]; then 
	echo $TIMESTAMP $lines found, skipping...
	
	else $TIMESTAMP $lines found, deleting...
		#remove log archives older than the specified number of days
		find $log_path -type f -name '*.zip' -mtime +$log_days -exec rm {} \;
	echo $TIMESTAMP "Cleaning up completed."		
fi

# Archive Current Logs
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Archiving current logs..."
tsm maintenance ziplogs -a -t -o -f logs-$DATE.zip -u $tsmuser -p $tsmpassword

# CleanUp older logs
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Cleaning up Tableau Server..."
tsm maintenance cleanup -a -u $tsmuser -p $tsmpassword
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Restarting Tableau Server"
tsm restart -u $tsmuser -p $tsmpassword
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
echo $TIMESTAMP "Housekeeping completed"