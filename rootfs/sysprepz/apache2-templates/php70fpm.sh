#!/bin/bash
# adding conf
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"
php_version="7.0"

fpm_conf="
[$domain]
user = $user
group = www-data

listen = /var/run/vesta-php-fpm-$domain.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.start_servers = 1
pm.max_children = 6
pm.min_spare_servers = 1
pm.max_spare_servers = 6
"
fpm_conf_file="$home_dir/$user/web/$domain/cgi-bin/php$php_version-fpm.conf"

echo "$fpm_conf" > $fpm_conf_file
chown $user:$user $fpm_conf_file
chmod -f 751 $fpm_conf_file

# create symbolic link to conf
ln -sf $fpm_conf_file /etc/php/$php_version/fpm/pool.d/$domain.conf

exit 0
