#!/bin/bash
# adding conf
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"
php_version="7.4"

fpm_conf="
[$domain]
listen = /var/run/vesta-php-fpm-$domain.sock
listen.allowed_clients = 127.0.0.1

user = $user
group = $user

listen.owner = $user
listen.group = www-data

pm = ondemand
pm.max_children = 4
pm.max_requests = 4000
pm.process_idle_timeout = 10s
pm.status_path = /status

php_admin_value[upload_tmp_dir] = /home/$user/web/$domain/tmp
php_admin_value[session.save_path] = /home/$user/web/$domain/tmp
php_admin_value[open_basedir] = $docroot:/home/$user/web/$domain/tmp

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /home/$user/tmp
env[TMPDIR] = /home/$user/tmp
env[TEMP] = /home/$user/tmp
"
fpm_conf_file="/home/$user/web/$domain/cgi-bin/php-fpm.conf"

# remove old conf
rm -f /home/$user/web/$domain/cgi-bin/php*-fpm.conf

# restart any *running* php fpm found with ps -uaxw
# otherwise, simply use: 
# find /etc/init.d/ -name 'php*-fpm*' -type f -exec basename {} \; | xargs -I{} service {} restart || true
phpfpms="7.2:7.3:7.4"

iphpfpm=(${phpfpms//:/ })
for i in "${!iphpfpm[@]}"
do
  if ps auxw | grep php/${iphpfpm[i]}/fpm | grep -v grep > /dev/null
  then
    service php${iphpfpm[i]}-fpm restart || true
  fi
done

# make sure to delete old sock file before restart
rm -f /var/run/vesta-php-fpm-$domain.sock || true

echo "$fpm_conf" > $fpm_conf_file
chown $user:$user $fpm_conf_file
chmod -f 751 $fpm_conf_file
mkdir -p /home/$user/web/$domain/tmp/cache
rm -rf /home/$user/web/$domain/tmp/*
chown $user:$user /home/$user/web/$domain/tmp
mkdir -p /home/$user/web/$domain/tmp/cache
chown -R www-data:www-data /home/$user/web/$domain/tmp/cache

# delete old and link new conf
rm -f /etc/php/*/fpm/pool.d/$domain.conf
ln -sf $fpm_conf_file /etc/php/$php_version/fpm/pool.d/$domain.conf


# start if it's not running
service php$php_version-fpm start || true
service php$php_version-fpm restart || true

service nginx restart || true

exit 0
