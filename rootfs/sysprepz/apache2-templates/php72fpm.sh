#!/bin/bash
# adding conf
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"
php_version="7.2"

fpm_conf="
[$domain]
user = $user
group = www-data

listen = /var/run/vesta-php-fpm-$domain.sock
listen.owner = $user
listen.group = www-data
listen.mode = 0660

pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
pm.max_requests = 2000
"
fpm_conf_file="$home_dir/$user/web/$domain/cgi-bin/php-fpm.conf"

# remove old conf
rm -f $home_dir/$user/web/$domain/cgi-bin/php*-fpm.conf

# restart any *running* php fpm found with ps -uaxw
# otherwise, simply use: 
# find /etc/init.d/ -name 'php*-fpm*' -type f -exec basename {} \; | xargs -I{} service {} restart || true
phpfpms="5.6:7.0:7.1:7.2:8.0"
set -f                      # avoid globbing (expansion of *).
iphpfpm=(${phpfpms//:/ })
for i in "${!iphpfpm[@]}"
do
  if ps auxw | grep php/${iphpfpm[i]}/fpm | grep -v grep > /dev/null
  then
    service php${iphpfpm[i]}-fpm restart || true
  fi
done

rm -f /var/run/vesta-php-fpm-$domain.sock || true

echo "$fpm_conf" > $fpm_conf_file
chown $user:$user $fpm_conf_file
chmod -f 751 $fpm_conf_file
rm -rf $home_dir/$user/web/$domain/tmp/cache
mkdir -p $home_dir/$user/web/$domain/tmp/cache
chown -R www-data:www-data $home_dir/$user/web/$domain/tmp/cache

# delete old and link new conf
rm -f /etc/php/*/fpm/pool.d/$domain.conf
ln -sf $fpm_conf_file /etc/php/$php_version/fpm/pool.d/$domain.conf


# start if it's not running
service php$php_version-fpm start || true
service php$php_version-fpm restart || true

service nginx restart || true

exit 0
