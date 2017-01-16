#!/bin/sh
# sync to s3, log to tmp, cleanup tmp
PATH="/home/admin/bin:/home/admin/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games"
export PATH
backup_dest=$(sed 's/\/*$//' <<< "$1")
backup_dest=$(sed 's/^\/*//' <<< "$backup_dest")

# this assume that you already ssh in as admin and run cli command "aws configure" to save your credential
aws s3 sync "/backup/" "s3://$backup_dest/" --exclude="*" --include "*.tar" >> /home/admin/tmp/aws-backup."$(date +%F_%R)".log
find /home/admin/tmp -type f -mtime +30 -exec rm -f {} \;
