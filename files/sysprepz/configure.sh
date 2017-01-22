#!/bin/sh
#
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

chmod +x /etc/init.d/dovecot \
    && chmod +x /etc/init.d/mongod \
    && chmod +x /etc/cron.hourly/vestacp-backup-etc \
    && chmod +x /etc/my_init.d/startup.sh

# mongodb stuff
# 
chmod 0755 /data/db
mkdir -p /data/db
chown -R mongodb:mongodb /data/db
chmod 755 /etc/init.d/disable-transparent-hugepages

# couchdb stuff
chown -R couchdb:couchdb /usr/bin/couchdb /etc/couchdb /usr/share/couchdb
chmod -R 0770 /usr/bin/couchdb /etc/couchdb /usr/share/couchdb
 
# secure ssh
sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config

# initialize ips for docker support
cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
    && cd /etc/apache2/conf.d \
    && sed -i -- 's/172.*.*.*:80/127.0.0.1:80/g' * && sed -i -- 's/172.*.*.*:8443/127.0.0.1:8443/g' * \
    && cd /etc/nginx/conf.d \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \
    && cd /home/admin/conf/web \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' *

# increase postgresql limit to support at least 8gb ram
sed -i -e "s/^max_connections = 100/max_connections = 300/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^shared_buffers = 128MB/shared_buffers = 2048MB/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/%q%u@%d '/%q%u@%d %r '/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

# php stuff - after vesta because of vesta-php installs
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/mods-available/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/mods-available/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/mods-available/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/mods-available/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/mods-available/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/mods-available/php.ini \


    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/mods-available/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.1/mods-available/php.ini \

    && echo "extension=v8js.so" > /etc/php/7.0/mods-available/v8js.ini \
    && echo "extension=v8js.so" > /etc/php/7.1/mods-available/v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/fpm/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/fpm/conf.d/20-v8js.ini \

    && echo "extension=couchbase.so" > /etc/php/7.0/mods-available/v8js.ini \
    && echo "extension=couchbase.so" > /etc/php/7.1/mods-available/v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/fpm/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/fpm/conf.d/20-v8js.ini \

    && service apache2 stop \
    && service mysql stop \
    && service postgresql stop \
    && service redis-server stop \
    && service fail2ban stop \
    && sed -i -e "s/\/var\/lib\/mysql/\/vesta\/var\/mysql/g" /etc/mysql/my.cnf \
    && sed -i -e "s/dir \./dir \/vesta\/redis\/db/g" /etc/redis/redis.conf \
    && sed -i -e "s/\/etc\/redis/\/vesta\/redis/g" /etc/init.d/redis-server \

    && mkdir -p /vesta-start/etc \
    && mkdir -p /vesta-start/etc-bak/apache2/conf.d \
    && mkdir -p /vesta-start/var \
    && mkdir -p /vesta-start/local \
    && mkdir -p /vesta-start/redis/db

# disable php*admin and roundcube by default, backup the config first - see README.md    
rsync -a /etc/apache2/conf.d/* /vesta-start/etc-bak/apache2/conf.d \
    && rm -rf /etc/apache2/conf.d/php*.conf \
    && rm -rf /etc/apache2/conf.d/roundcube.conf \

    && mv /etc/apache2 /vesta-start/etc/apache2 \
    && rm -rf /etc/apache2 \
    && ln -s /vesta/etc/apache2 /etc/apache2 \

    && mv /etc/php /vesta-start/etc/php \
    && rm -rf /etc/php \
    && ln -s /vesta/etc/php /etc/php \

    && mv /etc/nginx   /vesta-start/etc/nginx \
    && rm -rf /etc/nginx \
    && ln -s /vesta/etc/nginx /etc/nginx \

    && mv /etc/exim4   /vesta-start/etc/exim4 \
    && rm -rf /etc/exim4 \
    && ln -s /vesta/etc/exim4 /etc/exim4 \

    && mv /etc/redis   /vesta-start/etc/redis \
    && rm -rf /etc/redis \
    && ln -s /vesta/etc/redis /etc/redis \

    && mv /etc/dovecot /vesta-start/etc/dovecot \
    && rm -rf /etc/dovecot \
    && ln -s /vesta/etc/dovecot /etc/dovecot \

    && mv /etc/openvpn /vesta-start/etc/openvpn \
    && rm -rf /etc/openvpn \
    && ln -s /vesta/etc/openvpn /etc/openvpn \

    && mv /etc/mysql   /vesta-start/etc/mysql \
    && rm -rf /etc/mysql \
    && ln -s /vesta/etc/mysql /etc/mysql \

    && mv /var/lib/mysql /vesta-start/var/mysql \
    && rm -rf /var/lib/mysql \
    && ln -s /vesta/var/mysql /var/lib/mysql \
    
    && mv /var/lib/postgresql /vesta-start/var/postgresql \
    && rm -rf /var/lib/postgresql \
    && ln -s /vesta/var/postgresql /var/lib/postgresql \

    && mv /root /vesta-start/root \
    && rm -rf /root \
    && ln -s /vesta/root /root \

    && mv /usr/local/vesta /vesta-start/local/vesta \
    && rm -rf /usr/local/vesta \
    && ln -s /vesta/local/vesta /usr/local/vesta \

    && mv /etc/memcached.conf /vesta-start/etc/memcached.conf \
    && rm -rf /etc/memcached.conf \
    && ln -s /vesta/etc/memcached.conf /etc/memcached.conf \

    && mv /etc/timezone /vesta-start/etc/timezone \
    && rm -rf /etc/timezone \
    && ln -s /vesta/etc/timezone /etc/timezone \

    && mv /etc/bind /vesta-start/etc/bind \
    && rm -rf /etc/bind \
    && ln -s /vesta/etc/bind /etc/bind \

    && mv /etc/profile /vesta-start/etc/profile \
    && rm -rf /etc/profile \
    && ln -s /vesta/etc/profile /etc/profile \

    && mv /var/log /vesta-start/var/log \
    && rm -rf /var/log \
    && ln -s /vesta/var/log /var/log \

    && mv /etc/mongod.conf /vesta-start/etc/mongod.conf \
    && rm -rf /etc/mongod.conf \
    && ln -s /vesta/etc/mongod.conf /etc/mongod.conf \

    && mv /data /vesta-start/data \
    && rm -rf /var/data \
    && ln -s /vesta/data /var/data

    && mkdir -p /sysprepz/home
    && rsync -a /home/* /sysprepz/home \
    && mkdir -p /etc/my_init.d \

    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions

# fix docker nginx ips
sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.stpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.stpl \

    && bash /usr/local/vesta/upd/switch_rpath.sh 

# patch default website
cd "$(dirname "$(find /home/admin/web/* -type d -name public_html)")" \
    && sed -i -e "s/vestacp/nginx/g" public_html/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_html/index.html \
    && sed -i -e "s/vestacp/nginx/g" public_shtml/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_shtml/index.html

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

echo $'\nServerName localhost\n' >> /etc/apache2/apache2.conf \
    && sed -i -e "s/^ULIMIT_MAX_FILES=.*/ULIMIT_MAX_FILES=/g" /usr/sbin/apache2ctl

rm -rf /tmp/*