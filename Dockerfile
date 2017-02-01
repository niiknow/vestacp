FROM niiknow/docker-hostingbase:0.7.1

MAINTAINER friends@niiknow.org

ENV DEBIAN_FRONTEND=noninteractive
ENV VESTA=/usr/local/vesta DOTNET_VERSION=1.1.0 GOLANG_VERSION=1.7.5
ENV DOTNET_DOWNLOAD_URL=https://dotnetcli.blob.core.windows.net/dotnet/release/$DOTNET_VERSION/Binaries/$DOTNET_VERSION/dotnet-debian-x64.$DOTNET_VERSION.tar.gz
ENV GOLANG_DOWNLOAD_URL=https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz

# start
RUN \
    cd /tmp \
    && apt-get update && apt-get -y upgrade \

# install nodejs, memcached, redis-server, and openvpn
    && apt-get install -y nodejs memcached php-memcached redis-server openvpn \
    && npm install --quiet -g gulp express bower pm2 webpack webpack-dev-server karma protractor typings typescript \
    && npm cache clean \
    && ln -sf "$(which nodejs)" /usr/bin/node

# setting up mongodb, couchdb, dotnet, awscli, golang
RUN \
    cd /tmp \
    && apt-get install -yf mongodb-org php-mongodb couchdb  \

# dotnet
    && curl -SL $DOTNET_DOWNLOAD_URL --output /tmp/dotnet.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf /tmp/dotnet.tar.gz -C /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \

# awscli
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && pip install awscli \

# getting golang
    && cd /tmp \
    && curl -SL $GOLANG_DOWNLOAD_URL --output /tmp/golang.tar.gz \
    && tar -zxf golang.tar.gz \
    && mv go /usr/local \
    && echo "\nGOROOT=/usr/local/go\nexport GOROOT\n" >> /root/.profile

# install php
RUN \
    cd /tmp \
    && apt-get install -yq php5.6-mbstring php5.6-cgi php5.6-cli php5.6-dev php5.6-geoip php5.6-common php5.6-xmlrpc php5.6-sybase \
        php5.6-curl php5.6-enchant php5.6-imap php5.6-xsl php5.6-mysql php5.6-mysqlnd php5.6-pspell php5.6-gd php5.6-zip \
        php5.6-tidy php5.6-opcache php5.6-json php5.6-bz2 php5.6-pgsql php5.6-mcrypt php5.6-readline php5.6-imagick \
        php5.6-intl php5.6-sqlite3 php5.6-ldap php5.6-xml php5.6-redis libapache2-mod-php5.6 \

    && apt-get install -yq php7.0-mbstring php7.0-cgi php7.0-cli php7.0-dev php7.0-geoip php7.0-common php7.0-xmlrpc php7.0-sybase \
        php7.0-curl php7.0-enchant php7.0-imap php7.0-xsl php7.0-mysql php7.0-mysqlnd php7.0-pspell php7.0-gd php7.0-zip \
        php7.0-tidy php7.0-opcache php7.0-json php7.0-bz2 php7.0-pgsql php7.0-mcrypt php7.0-readline php7.0-imagick \
        php7.0-intl php7.0-sqlite3 php7.0-ldap php7.0-xml php7.0-redis libapache2-mod-php7.0 \

    && apt-get install -yq php7.1-mbstring php7.1-cgi php7.1-cli php7.1-dev php7.1-geoip php7.1-common php7.1-xmlrpc php7.1-sybase \
        php7.1-curl php7.1-enchant php7.1-imap php7.1-xsl php7.1-mysql php7.1-mysqlnd php7.1-pspell php7.1-gd php7.1-zip \
        php7.1-tidy php7.1-opcache php7.1-json php7.1-bz2 php7.1-pgsql php7.1-mcrypt php7.1-readline php7.1-imagick \
        php7.1-intl php7.1-sqlite3 php7.1-ldap php7.1-xml php7.1-redis libapache2-mod-php7.1 \

# fix v8js reference of json first
    && mv /etc/php/5.6/cli/conf.d/20-json.ini /etc/php/5.6/cli/conf.d/15-json.ini \
    && mv /etc/php/5.6/cgi/conf.d/20-json.ini /etc/php/5.6/cgi/conf.d/15-json.ini \
    && a2dismod php5.6 && a2dismod php7.0 && a2dismod php7.1 \

# switch to php7.0 version before any other install
    && update-alternatives --set php /usr/bin/php7.0 \
    && pecl config-set php_ini /etc/php/7.0/cli/php.ini \
    && pecl config-set ext_dir /usr/lib/php/20151012 \
    && pecl config-set bin_dir /usr/bin \
    && pecl config-set php_bin /usr/bin/php7.0 \
    && pecl config-set php_suffix 7.0 

RUN \
    cd /tmp \
    && curl -s -o /tmp/vst-install-ubuntu.sh https://vestacp.com/pub/vst-install-ubuntu.sh \

# fix mariadb instead of mysql and php7.0 instead of php7.1
    && sed -i -e "s/mysql\-/mariadb\-/g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/\-php php /\-php php7\.0 /g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/php\-/php7\.0\-/g" /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/libapache2\-mod\-php/libapache2-mod\-php7\.0/g" /tmp/vst-install-ubuntu.sh \

# begin VestaCP install
    && bash /tmp/vst-install-ubuntu.sh \
        --nginx yes --apache yes --phpfpm no \
        --vsftpd no --proftpd no \
        --named yes --exim yes --dovecot yes \
        --spamassassin yes --clamav yes \
        --iptables yes --fail2ban yes \
        --mysql yes --postgresql yes --remi yes \
        --quota no --password MakeItSo17 \
        -y no -f \

# cleanup
    && rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean 

ADD ./files /

# tweaks
RUN \
    cd /tmp \
    chmod +x /etc/init.d/dovecot \
    && chmod +x /etc/service/sshd/run \
    && chmod +x /etc/init.d/mongod \
    && chmod +x /etc/cron.hourly/vestacp-backup-etc \
    && chmod +x /etc/my_init.d/startup.sh \

    && echo "extension=v8js.so" > /etc/php/5.6/mods-available/v8js.ini \
    && ln -sf /etc/php/5.6/mods-available/v8js.ini /etc/php/5.6/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/5.6/mods-available/v8js.ini /etc/php/5.6/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/5.6/mods-available/v8js.ini /etc/php/5.6/cgi/conf.d/20-v8js.ini \

    && echo "extension=v8js.so" > /etc/php/7.0/mods-available/v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.0/mods-available/v8js.ini /etc/php/7.0/cgi/conf.d/20-v8js.ini \

    && echo "extension=v8js.so" > /etc/php/7.1/mods-available/v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/cgi/conf.d/20-v8js.ini \



    && echo "extension=pcs.so" > /etc/php/5.6/mods-available/pcs.ini \
    && ln -sf /etc/php/5.6/mods-available/pcs.ini /etc/php/5.6/apache2/conf.d/15-pcs.ini \
    && ln -sf /etc/php/5.6/mods-available/pcs.ini /etc/php/5.6/cli/conf.d/15-pcs.ini \
    && ln -sf /etc/php/5.6/mods-available/pcs.ini /etc/php/5.6/cgi/conf.d/15-pcs.ini \

    && echo "extension=pcs.so" > /etc/php/7.0/mods-available/pcs.ini \
    && ln -sf /etc/php/7.0/mods-available/pcs.ini /etc/php/7.0/apache2/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.0/mods-available/pcs.ini /etc/php/7.0/cli/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.0/mods-available/pcs.ini /etc/php/7.0/cgi/conf.d/15-pcs.ini \

    && echo "extension=pcs.so" > /etc/php/7.1/mods-available/pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/apache2/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/cli/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/cgi/conf.d/15-pcs.ini \


    && echo "extension=couchbase.so" > /etc/php/5.6/mods-available/couchbase.ini \
    && ln -sf /etc/php/5.6/mods-available/couchbase.ini /etc/php/5.6/apache2/conf.d/20-couchbase.ini \
    && ln -sf /etc/php/5.6/mods-available/couchbase.ini /etc/php/5.6/cli/conf.d/20-couchbase.ini \
    && ln -sf /etc/php/5.6/mods-available/couchbase.ini /etc/php/5.6/cgi/conf.d/20-couchbase.ini \

    && echo "extension=couchbase.so" > /etc/php/7.0/mods-available/couchbase.ini \
    && ln -sf /etc/php/7.0/mods-available/couchbase.ini /etc/php/7.0/apache2/conf.d/20-couchbase.ini \
    && ln -sf /etc/php/7.0/mods-available/couchbase.ini /etc/php/7.0/cli/conf.d/20-couchbase.ini \
    && ln -sf /etc/php/7.0/mods-available/couchbase.ini /etc/php/7.0/cgi/conf.d/20-couchbase.ini \

    && echo "extension=couchbase.so" > /etc/php/7.1/mods-available/couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/apache2/conf.d/20-couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/cli/conf.d/20-couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/cgi/conf.d/20-couchbase.ini \


    && a2enmod php7.0 \

# increase memcache max size from 64m to 2g
    && sed -i -e "s/^\-m 64/\-m 2048/g" /etc/memcached.conf \

# mongodb stuff
    && mkdir -p /data/db \
    && chmod 0755 /data/db \
    && chown -R mongodb:mongodb /data/db \
    && chmod 0755 /etc/init.d/disable-transparent-hugepages \

# couchdb stuff
    && mkdir -p /var/lib/couchdb \
    && chown -R couchdb:couchdb /usr/bin/couchdb /etc/couchdb /usr/share/couchdb /var/lib/couchdb  \
    && chmod -R 0770 /usr/bin/couchdb /etc/couchdb /usr/share/couchdb /var/lib/couchdb \
 
# secure ssh
    && sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config \

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

# php stuff - after vesta because of vesta-php installs
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.0/cgi/php.ini \

    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/5.6/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/5.6/cgi/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cgi/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.0/cgi/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/5.6/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/5.6/cgi/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cgi/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.0/cgi/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/5.6/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/5.6/cgi/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cgi/php.ini \

    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.0/cgi/php.ini \

    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/5.6/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/5.6/cgi/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.1/cgi/php.ini \

    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.0/apache2/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.0/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.0/cgi/php.ini \

    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/5.6/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/5.6/cgi/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/cgi/php.ini \

# fix docker nginx ips
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.stpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.stpl \
    && bash /usr/local/vesta/upd/switch_rpath.sh \

# remove rlimit in docker nginx
    && sed -i -e "s/^worker_rlimit_nofile    65535;//g" /etc/nginx/nginx.conf \

# vesta monkey patching
# patch psql9.5 backup
    && sed -i -e "s/\-x \-i \-f/\-x \-f/g" /usr/local/vesta/func/db.sh \

# https://github.com/serghey-rodin/vesta/issues/1009
    && sed -i -e "s/unzip/unzip \-o/g" /usr/local/vesta/bin/v-extract-fs-archive \

    && echo "\nServerName localhost\n" >> /etc/apache2/apache2.conf \
    && sed -i -e "s/^ULIMIT_MAX_FILES=.*/ULIMIT_MAX_FILES=/g" /usr/sbin/apache2ctl \

# disable localhost redirect to bad default IP
    && sed -i -e "s/^NAT=.*/NAT=\'\'/g" /usr/local/vesta/data/ips/* \

    && service mysql stop \
    && service postgresql stop \
    && service redis-server stop \
    && service fail2ban stop \
    && sed -i -e "s/\/var\/lib\/mysql/\/vesta\/var\/lib\/mysql/g" /etc/mysql/my.cnf \
    && sed -i -e "s/127\.0\.0\.1/\*/g" /etc/redis/redis.conf \
    && sed -i -e "s/\/etc\/redis/\/vesta\/etc\/redis/g" /etc/init.d/redis-server \

    && mkdir -p /vesta-start/etc \
    && mkdir -p /vesta-start/etc-bak/apache2/conf.d \
    && mkdir -p /vesta-start/var/lib \
    && mkdir -p /vesta-start/local \

# disable php*admin and roundcube by default, backup the config first - see README.md    
    && rsync -a /etc/apache2/conf.d/* /vesta-start/etc-bak/apache2/conf.d \
    && rm -f /etc/apache2/conf.d/php*.conf \
    && rm -f /etc/apache2/conf.d/roundcube.conf \

    && mv /etc/apache2 /vesta-start/etc/apache2 \
    && rm -rf /etc/apache2 \
    && ln -s /vesta/etc/apache2 /etc/apache2 \

    && mv /etc/ssh /vesta-start/etc/ssh \
    && rm -rf /etc/ssh \
    && ln -s /vesta/etc/ssh /etc/ssh \

    && mv /etc/fail2ban /vesta-start/etc/fail2ban \
    && rm -rf /etc/fail2ban \
    && ln -s /vesta/etc/fail2ban /etc/fail2ban \

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

    && mkdir -p /var/lib/redis \
    && chown -R redis:redis /var/lib/redis \
    && mv /var/lib/redis /vesta-start/var/lib/redis \
    && rm -rf /var/lib/redis \
    && ln -s /vesta/var/lib/redis /var/lib/redis \

    && mv /etc/dovecot /vesta-start/etc/dovecot \
    && rm -rf /etc/dovecot \
    && ln -s /vesta/etc/dovecot /etc/dovecot \

    && mv /etc/openvpn /vesta-start/etc/openvpn \
    && rm -rf /etc/openvpn \
    && ln -s /vesta/etc/openvpn /etc/openvpn \

    && mv /etc/mysql   /vesta-start/etc/mysql \
    && rm -rf /etc/mysql \
    && ln -s /vesta/etc/mysql /etc/mysql \

    && mv /var/lib/mysql /vesta-start/var/lib/mysql \
    && rm -rf /var/lib/mysql \
    && ln -s /vesta/var/lib/mysql /var/lib/mysql \
    
    && mv /etc/postgresql   /vesta-start/etc/postgresql \
    && rm -rf /etc/postgresql \
    && ln -s /vesta/etc/postgresql /etc/postgresql \

    && mv /var/lib/postgresql /vesta-start/var/lib/postgresql \
    && rm -rf /var/lib/postgresql \
    && ln -s /vesta/var/lib/postgresql /var/lib/postgresql \

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
    && rm -rf /data \
    && ln -s /vesta/data /data \

    && mv /etc/couchdb /vesta-start/etc/couchdb \
    && rm -rf /etc/couchdb \
    && ln -s /vesta/etc/couchdb /etc/couchdb \

    && mv /var/lib/couchdb /vesta-start/var/lib/couchdb \
    && rm -rf /var/lib/couchdb \
    && ln -s /vesta/var/lib/couchdb /var/lib/couchdb \

    && mkdir -p /sysprepz/home \
    && rsync -a /home/* /sysprepz/home \

    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions \

# patch default website
    && cd "$(dirname "$(find /home/admin/web/* -type d -name public_html)")" \
    && sed -i -e "s/vestacp/nginx/g" public_html/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_html/index.html \
    && sed -i -e "s/vestacp/nginx/g" public_shtml/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_shtml/index.html \

    && rm -rf /tmp/*


VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 5984 6379 8083 10022 11211 27017
