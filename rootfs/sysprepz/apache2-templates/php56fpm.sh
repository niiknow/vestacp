#!/bin/bash
# adding conf
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"
php_version="5.6"

fpm_conf="
[$domain]
user = $user
group = www-data

listen = /var/run/vesta-php-fpm-$domain.sock
listen.owner = $user
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.start_servers = 1
pm.max_children = 6
pm.min_spare_servers = 1
pm.max_spare_servers = 6
"
fpm_conf_file="$home_dir/$user/web/$domain/cgi-bin/php-fpm.conf"

echo "$fpm_conf" > $fpm_conf_file
chown $user:$user $fpm_conf_file
chmod -f 751 $fpm_conf_file
rm -rf $home_dir/$user/web/$domain/tmp/cache
mkdir -p $home_dir/$user/web/$domain/tmp/cache
chown -R www-data:www-data $home_dir/$user/web/$domain/tmp/cache

# delete old and link new conf
rm -f /etc/php/*/fpm/pool.d/$domain.conf
ln -sf $fpm_conf_file /etc/php/$php_version/fpm/pool.d/$domain.conf

# restart if it's already running
ps auxw | grep php/5.6/fpm | grep -v grep > /dev/null
if [ $? != 0 ]
then
  service php5.6-fpm restart || true
fi
ps auxw | grep php/7.0/fpm | grep -v grep > /dev/null
if [ $? != 0 ]
then
   service php7.0-fpm restart || true
fi
ps auxw | grep php/7.1/fpm | grep -v grep > /dev/null
if [ $? != 0 ]
then
   service php7.1-fpm restart || true
fi

# start if it's not running
service php$php_version-fpm start || true

service nginx restart || true

exit 0
