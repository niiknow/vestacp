FROM niiknow/docker-hostingbase

MAINTAINER friends@niiknow.org

ENV VESTA=/usr/local/vesta
ENV DEBIAN_FRONTEND=noninteractive

# install composer, nodejs
RUN curl -sS https://getcomposer.org/installer | php -- --version=1.3.0 --install-dir=/usr/local/bin --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - \
    && apt-get update && apt-get -y upgrade \
    && apt-get install -y nodejs php-memcached php-mongodb \
    && npm install --quiet -g gulp express bower mocha karma-cli pm2 && npm cache clean \
    && ln -sf /usr/bin/nodejs /bin/node \

# getting golang
    && cd /tmp \
    && curl -s -o /tmp/go1.7.4.linux-amd64.tar.gz https://storage.googleapis.com/golang/go1.7.4.linux-amd64.tar.gz \
    && tar -zxf go1.7.4.linux-amd64.tar.gz \
    && mv go /usr/local \

# install VestaCP
    && curl -s -o /tmp/vst-install-ubuntu.sh https://vestacp.com/pub/vst-install-ubuntu.sh \

# fix mariadb instead of mysql and php7.0 instead of php7.1
    && sed -i -e "s/mysql\-/mariadb\-/g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/ php / php7.0 /g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/php\-/php7.0\-/g" /tmp/vst-install-ubuntu.sh \

# begin VestaCP install
    && bash /tmp/vst-install-ubuntu.sh \
    --nginx yes --apache yes --phpfpm no \
    --vsftpd no --proftpd no \
    --exim yes --dovecot yes --spamassassin yes --clamav yes --named yes \
    --iptables yes --fail2ban yes \
    --mysql yes --postgresql yes --remi yes \
    --quota no --password MakeItSo17 \
    -y no -f \

# fix exim4 issue starting on ubuntu
    && apt-get install -y exim4-daemon-heavy \
    && apt-get -yf autoremove \
    && apt-get clean

ADD ./files /
RUN chmod +x /etc/init.d/dovecot \
    && chmod +x /etc/cron.hourly/vestacp-backup-etc \
    && chmod +x /etc/my_init.d/startup.sh \
    && rm -f /etc/service/sshd/down \
    && /etc/my_init.d/00_regen_ssh_host_keys.sh \

# initialize ips for docker support
    && cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
    && cd /etc/apache2/conf.d \
    && sed -i -- 's/172.*.*.*:80/127.0.0.1:80/g' * && sed -i -- 's/172.*.*.*:8443/127.0.0.1:8443/g' * \
    && cd /etc/nginx/conf.d \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \
    && cd /home/admin/conf/web \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \

# increase postgresql limit to support at least 8gb ram
    && sed -i -e "s/^max_connections = 100/max_connections = 300/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^shared_buffers = 128MB/shared_buffers = 2048MB/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/%q%u@%d '/%q%u@%d %r '/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf \
    && sed -i -e "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config \

# redirect sql data folder
    && service apache2 stop \
    && service mysql stop \
    && service postgresql stop \
    && service redis-server stop \
    && service fail2ban stop \
    && sed -i -e "s/\/var\/lib\/mysql/\/vesta\/var\/mysql/g" /etc/mysql/my.cnf \
    && sed -i -e "s/dir \./dir \/vesta\/redis\/db/g" /etc/redis/redis.conf \
    && sed -i -e "s/\/etc\/redis/\/vesta\/redis/g" /etc/init.d/redis-server \

# the rest
    && mkdir -p /vesta-start/etc \
    && mkdir -p /vesta-start/etc-bak/apache2/conf.d \
    && mkdir -p /vesta-start/var \
    && mkdir -p /vesta-start/local \
    && mkdir -p /vesta-start/redis/db \

# disable php*admin and roundcube by default, backup the config first - see README.md    
    && rsync -a /etc/apache2/conf.d/* /vesta-start/etc-bak/apache2/conf.d \
    && rm -rf /etc/apache2/conf.d/php*.conf \
    && rm -rf /etc/apache2/conf.d/roundcube.conf \

# redirecting folders
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

    && mv /etc/bind /vesta-start/etc/bind \
    && rm -rf /etc/bind \
    && ln -s /vesta/etc/bind /etc/bind \

    && mv /etc/profile /vesta-start/etc/profile \
    && rm -rf /etc/profile \
    && ln -s /vesta/etc/profile /etc/profile \

    && mv /var/log /vesta-start/var/log \
    && rm -rf /var/log \
    && ln -s /vesta/var/log /var/log \

# redirecting home folder
    && mkdir -p /home-bak \
    && rsync -a /home/* /home-bak \
    && mkdir -p /etc/my_init.d \
    && rm -rf /tmp/* \

# vesta session
    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions

# php apache2 stuff
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /vesta-start/etc/php/7.0/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 100M/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 100M/" /vesta-start/etc/php/7.0/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /vesta-start/etc/php/7.0/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /vesta-start/etc/php/7.0/cli/php.ini 

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 3306 5432 6379 8083 10022 11211
