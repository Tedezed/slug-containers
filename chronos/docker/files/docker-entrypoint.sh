#!/bin/bash
# By: Juan Manuel Torres (Tedezed)

set -e

echo "ver 1.0"

# #export PYTHONIOENCODING="UTF-8"
# echo "
# import sys
# reload(sys)
# sys.setdefaultencoding('utf-8')
# " >> /usr/lib/python2.7/sitecustomize.py

# Drop /etc/crontab
echo > /etc/crontab

printenv | grep -v "TIME" | sed 's/^\(.*\)$/export \1/g' > /root/project_env
chmod +x /root/project_env

echo "$TIME /bin/bash /backup-db-cron/start >> /backup-db-cron/backups/cron.log 2>&1" > /etc/crontab
echo "0 0 15 * * echo '' > /backup-db-cron/backups/cron.log" >> /etc/crontab
echo "0 0 15 * * echo '' >/backup-db-cron/backups/kube-backup.log" >> /etc/crontab
crontab /etc/crontab

# Start
cron -f

exit 0