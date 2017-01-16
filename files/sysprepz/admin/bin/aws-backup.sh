#!/bin/sh
# sync to s3, log to tmp, cleanup tmp
PATH="/home/admin/bin:/home/admin/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games"
export PATH

aws s3 sync '/backup/' 's3://brick-backups/gogs201701/' --exclude="*" --include "*.tar" >> /home/admin/tmp/aws-backup."$(date +%F_%R)".log
find /home/admin/tmp -type f -mtime +30 -exec rm -f {} \;