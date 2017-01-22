#!/bin/sh
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

export DEBIAN_FRONTEND=noninteractive

/tmp/install/php.sh
/tmp/install/vesta.sh

# cleanup
rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean

# since we're running this as a server, comment out removal of app/lists
# rm -rf /var/lib/apt/lists/*

# Monkey patching for docker
# make default template work with any IP, we want this for Docker
sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.tpl
sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.stpl
sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.tpl
sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.stpl

bash /usr/local/vesta/upd/switch_rpath.sh

# patch default website
cd "$(dirname "$(find /home/admin/web/* -type d -name public_html)")" \
&& sed -i -e "s/vestacp/nginx/g" public_html/index.html \
&& sed -i -e "s/VESTA/NGINX/g" public_html/index.html \
&& sed -i -e "s/vestacp/nginx/g" public_shtml/index.html \
&& sed -i -e "s/VESTA/NGINX/g" public_shtml/index.html \

cd /tmp

# disable localhost redirect to bad default IP
sed -i -e "s/^NAT=.*/NAT=\'\'/g" /usr/local/vesta/data/ips/127.0.0.1

# increase memcache max size from 64m to 2g
sed -i -e "s/^\-m 64/\-m 2048/g" /usr/etc/memcached.conf

# remove rlimit in docker nginx
sed -i -e "s/^worker_rlimit_nofile    65535;//g" /etc/nginx/nginx.conf

# vesta monkey patching
# patch psql9.5 backup
sed -i -e "s/\-x \-i \-f/\-x \-f/g" /usr/local/vesta/func/db.sh

# https://github.com/serghey-rodin/vesta/issues/1009
sed -i -e "s/unzip/unzip \-o/g" /usr/local/vesta/bin/v-extract-fs-archive

echo $'\nServerName localhost\n' >> /etc/apache2/apache2.conf
sed -i -e "s/^ULIMIT_MAX_FILES=.*/ULIMIT_MAX_FILES=/g" /usr/sbin/apache2ctl
