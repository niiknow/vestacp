#!/bin/sh

export VESTA=/usr/local/vesta

cd /tmp
curl -s -o /tmp/vst-install-ubuntu.sh https://vestacp.com/pub/vst-install-ubuntu.sh

# fix mariadb instead of mysql and php7.0 instead of php7.1
sed -i -e "s/mysql\-/mariadb\-/g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/\-php php /\-php php7\.0 /g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/php\-/php7\.0\-/g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/libapache2\-mod\-php/libapache2-mod\-php7\.0/g" /tmp/vst-install-ubuntu.sh

# begin VestaCP install
bash /tmp/vst-install-ubuntu.sh \
       --nginx yes --apache yes --phpfpm no \
       --vsftpd no --proftpd no \
       --named yes --exim yes --dovecot yes \
       --spamassassin yes --clamav yes \
       --iptables yes --fail2ban yes \
       --mysql yes --postgresql yes --remi yes \
       --quota no --password MakeItSo17 \
       -y no -f

# php stuff - after vesta because of vesta-php installs
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cli/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cli/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cli/php.ini \

    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.1/cli/php.ini

# mongodb stuff
chmod 755 /etc/init.d/disable-transparent-hugepages

# secure ssh
sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config

chmod +x /etc/init.d/dovecot \
    && chmod +x /etc/init.d/mongod \
    && chmod +x /etc/cron.hourly/vestacp-backup-etc \
    && chmod +x /etc/my_init.d/startup.sh \
#    && rm -f /etc/service/sshd/down \

# initialize ips for docker support
cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
    && cd /etc/apache2/conf.d \
    && sed -i -- 's/172.*.*.*:80/127.0.0.1:80/g' * && sed -i -- 's/172.*.*.*:8443/127.0.0.1:8443/g' * \
    && cd /etc/nginx/conf.d \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \
    && cd /home/admin/conf/web \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' *

cd /tmp

# increase postgresql limit to support at least 8gb ram
sed -i -e "s/^max_connections = 100/max_connections = 300/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^shared_buffers = 128MB/shared_buffers = 2048MB/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/%q%u@%d '/%q%u@%d %r '/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

# redirect sql data folder
service apache2 stop \
    && service mysql stop \
    && service postgresql stop \
    && service redis-server stop \
    && service fail2ban stop \
    && sed -i -e "s/\/var\/lib\/mysql/\/vesta\/var\/mysql/g" /etc/mysql/my.cnf \
    && sed -i -e "s/dir \./dir \/vesta\/redis\/db/g" /etc/redis/redis.conf \
    && sed -i -e "s/\/etc\/redis/\/vesta\/redis/g" /etc/init.d/redis-server

# the rest
mkdir -p /vesta-start/etc \
    && mkdir -p /vesta-start/etc-bak/apache2/conf.d \
    && mkdir -p /vesta-start/var \
    && mkdir -p /vesta-start/local \
    && mkdir -p /vesta-start/redis/db

# disable php*admin and roundcube by default, backup the config first - see README.md    
rsync -a /etc/apache2/conf.d/* /vesta-start/etc-bak/apache2/conf.d \
    && rm -rf /etc/apache2/conf.d/php*.conf \
    && rm -rf /etc/apache2/conf.d/roundcube.conf

# redirect folders
mv /etc/apache2 /vesta-start/etc/apache2 \
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
    && ln -s /vesta/var/log /var/log

# mongodb conf and /data/db
mv /etc/mongod.conf /vesta-start/etc/mongod.conf \
    && rm -rf /etc/mongod.conf \
    && ln -s /vesta/etc/mongod.conf /etc/mongod.conf \

    && mkdir -p /data/db \
    && chmod 0755 /data/db
    && chown -R mongod:mongod /data/db
    && mv /data /vesta-start/data \
    && rm -rf /var/data \
    && ln -s /vesta/data /var/data

# redirect home folder
mkdir -p /sysprepz/home
    && rsync -a /home/* /sysprepz/home \
    && mkdir -p /etc/my_init.d

# vesta session
mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions
