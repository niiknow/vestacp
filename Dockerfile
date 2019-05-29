FROM niiknow/docker-hostingbase:1.4.2
LABEL maintainer="noogen <friends@niiknow.org>"
ENV DEBIAN_FRONTEND=noninteractive \
    VESTA=/usr/local/vesta \
    GOLANG_VERSION=1.12.5 \
    NGINX_BUILD_DIR=/usr/src/nginx \
    NGINX_DEVEL_KIT_VERSION=0.3.0 NGINX_SET_MISC_MODULE_VERSION=0.32 \
    NGINX_VERSION=1.16.0 \
    NGINX_PAGESPEED_VERSION=1.13.35.2 \
    NGINX_PSOL_VERSION=1.13.35.2 \
    IMAGE_FILTER_URL=https://raw.githubusercontent.com/niiknow/docker-nginx-image-proxy/master/build/src/ngx_http_image_filter_module.c

RUN cd /tmp \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 91FA4AD5 \
    && add-apt-repository ppa:deadsnakes/ppa \
    && add-apt-repository ppa:maxmind/ppa -y \
    && echo "nginx mysql bind clamav ssl-cert dovecot dovenull Debian-exim postgres debian-spamd epmd couchdb memcache mongodb redis" | xargs -n1 groupadd -K GID_MIN=100 -K GID_MAX=999 ${g} \
    && echo "nginx nginx mysql mysql bind bind clamav clamav dovecot dovecot dovenull dovenull Debian-exim Debian-exim postgres postgres debian-spamd debian-spamd epmd epmd couchdb couchdb memcache memcache mongodb mongodb redis redis" | xargs -n2 useradd -d /nonexistent -s /bin/false -K UID_MIN=100 -K UID_MAX=999 -g ${g} \
    && usermod -d /var/lib/mysql mysql \
    && usermod -d /var/cache/bind bind \
    && usermod -d /var/lib/clamav -a -G Debian-exim clamav && usermod -a -G mail clamav \
    && usermod -d /usr/lib/dovecot -a -G mail dovecot \
    && usermod -d /var/spool/exim4 -a -G mail Debian-exim \
    && usermod -d /var/lib/postgresql -s /bin/bash -a -G ssl-cert postgres \
    && usermod -d /var/lib/spamassassin -s /bin/sh -a -G mail debian-spamd \
    && usermod -d /var/run/epmd epmd \
    && usermod -d /var/lib/couchdb -s /bin/bash couchdb \
    && usermod -d /var/lib/mongodb -a -G nogroup mongodb \
    && usermod -d /var/lib/redis redis \
    && add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
    && add-apt-repository ppa:ubuntugis/ubuntugis-unstable \
    && curl -sL "https://github.com/simplresty/ngx_devel_kit/archive/v$NGINX_DEVEL_KIT_VERSION.tar.gz" -o dev-kit.tar.gz \
    && mkdir -p /usr/src/nginx/ngx_devel_kit \
    && tar -xof dev-kit.tar.gz -C /usr/src/nginx/ngx_devel_kit --strip-components=1 \
    && rm dev-kit.tar.gz \
    && curl -sL "https://github.com/openresty/set-misc-nginx-module/archive/v$NGINX_SET_MISC_MODULE_VERSION.tar.gz" -o ngx-misc.tar.gz \
    && mkdir -p /usr/src/nginx/set-misc-nginx-module \
    && tar -xof ngx-misc.tar.gz -C /usr/src/nginx/set-misc-nginx-module --strip-components=1 \
    && rm ngx-misc.tar.gz \
    && curl -s https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    && echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
    && apt-get update && apt-get -y --no-install-recommends upgrade \
    && curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - \
    && apt-get install -y --no-install-recommends libpcre3-dev libssl-dev dpkg-dev libmaxminddb0 libmaxminddb-dev mmdb-bin libgd-dev iproute uuid-dev \
    && mkdir -p ${NGINX_BUILD_DIR} \
    && cd ${NGINX_BUILD_DIR} \
    && git clone https://github.com/leev/ngx_http_geoip2_module ngx_http_geoip2_module \
    && apt-get source nginx=${NGINX_VERSION} -y \
    && mv ${NGINX_BUILD_DIR}/nginx-${NGINX_VERSION}/src/http/modules/ngx_http_image_filter_module.c ${NGINX_BUILD_DIR}/nginx-${NGINX_VERSION}/src/http/modules/ngx_http_image_filter_module.bak \
    && curl -SL $IMAGE_FILTER_URL --output ${NGINX_BUILD_DIR}/nginx-${NGINX_VERSION}/src/http/modules/ngx_http_image_filter_module.c \
    && sed -i "s/--with-http_ssl_module/--with-http_ssl_module --with-http_image_filter_module --add-module=\/usr\/src\/nginx\/ngx_http_geoip2_module --add-module=\/usr\/src\/nginx\/ngx_devel_kit --add-module=\/usr\/src\/nginx\/set-misc-nginx-module --add-module=\/usr\/src\/nginx\/ngx_pagespeed-latest-stable/g" ${NGINX_BUILD_DIR}/nginx-${NGINX_VERSION}/debian/rules \
    && curl -SL https://github.com/apache/incubator-pagespeed-ngx/archive/v${NGINX_PAGESPEED_VERSION}-stable.zip -o latest-stable.zip \
    && unzip latest-stable.zip \
    && mv incubator-pagespeed-ngx-${NGINX_PAGESPEED_VERSION}-stable ngx_pagespeed-latest-stable \
    && cd ngx_pagespeed-latest-stable \
    && curl -SL https://dl.google.com/dl/page-speed/psol/${NGINX_PSOL_VERSION}-x64.tar.gz -o ${NGINX_PSOL_VERSION}.tar.gz \
    && tar -xzf ${NGINX_PSOL_VERSION}.tar.gz \
    && apt-get build-dep nginx -y \
    && cd ${NGINX_BUILD_DIR}/nginx-${NGINX_VERSION}; dpkg-buildpackage -uc -us -b \
    && cd ${NGINX_BUILD_DIR} \
    && dpkg -i nginx_${NGINX_VERSION}-1~xenial_amd64.deb \
    && apt-get install -yq php7.1-mbstring php7.1-cgi php7.1-cli php7.1-dev php7.1-geoip php7.1-common php7.1-xmlrpc php7.1-sybase php7.1-curl \
        php7.1-enchant php7.1-imap php7.1-xsl php7.1-mysql php7.1-mysqli php7.1-mysqlnd php7.1-pspell php7.1-gd php7.1-zip \
        php7.1-tidy php7.1-opcache php7.1-json php7.1-bz2 php7.1-pgsql php7.1-mcrypt php7.1-readline php7.1-imagick \
        php7.1-intl php7.1-sqlite3 php7.1-ldap php7.1-xml php7.1-redis php7.1-dev php7.1-fpm php7.1-sodium \
        php7.1-soap php7.1-bcmath php7.1-fileinfo php7.1-xdebug php7.1-exif php7.1-tokenizer php7.1-phar \
    && apt-get install -yq php7.2-mbstring php7.2-cgi php7.2-cli php7.2-dev php7.2-geoip php7.2-common php7.2-xmlrpc php7.2-sybase php7.2-curl \
        php7.2-enchant php7.2-imap php7.2-xsl php7.2-mysql php7.2-mysqli php7.2-mysqlnd php7.2-pspell php7.2-gd php7.2-zip \
        php7.2-tidy php7.2-opcache php7.2-json php7.2-bz2 php7.2-pgsql php7.2-readline php7.2-imagick php7.2-phar \
        php7.2-intl php7.2-sqlite3 php7.2-ldap php7.2-xml php7.2-redis php7.2-dev php7.2-fpm \
        php7.2-soap php7.2-bcmath php7.2-fileinfo php7.2-xdebug php7.2-exif php7.2-tokenizer \
    && apt-get install -yq php7.3-mbstring php7.3-cgi php7.3-cli php7.3-dev php7.3-geoip php7.3-common php7.3-xmlrpc php7.3-sybase php7.3-curl \
        php7.3-enchant php7.3-imap php7.3-xsl php7.3-mysql php7.3-mysqli php7.3-mysqlnd php7.3-pspell php7.3-gd php7.3-zip \
        php7.3-tidy php7.3-opcache php7.3-json php7.3-bz2 php7.3-pgsql php7.3-readline php7.3-imagick php7.3-phar \
        php7.3-intl php7.3-sqlite3 php7.3-ldap php7.3-xml php7.3-redis php7.3-dev php7.3-fpm \
        php7.3-soap php7.3-bcmath php7.3-fileinfo php7.3-xdebug php7.3-exif php7.3-tokenizer \

# put nginx on hold so it doesn't get updates with apt-get upgrade, also remove from vesta apt-get
    && apt-mark hold nginx \
    && rm -f /etc/apt/sources.list && mv /etc/apt/sources.list.bak /etc/apt/sources.list \
    && rm -rf /usr/src/nginx \
    && rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean 

RUN cd /tmp \
    && touch /var/log/auth.log \
# begin setup for vesta
    && curl -SL https://raw.githubusercontent.com/serghey-rodin/vesta/3acd2281699fcaede439da0687d64586525a15a1/install/vst-install-ubuntu.sh -o /tmp/vst-install-ubuntu.sh \
    && sed -i -e "s/software\=\"nginx /software\=\"/g" /tmp/vst-install-ubuntu.sh \

# fix mariadb instead of mysql
    && sed -i -e "s/mysql\-/mariadb\-/g" /tmp/vst-install-ubuntu.sh \

# fix postgres-9.6 instead of 9.5
    && sed -i -e "s/postgresql postgresql-contrib /postgresql\-9\.6 postgresql\-contrib\-9\.6 postgresql\-client\-9\.6 /g" /tmp/vst-install-ubuntu.sh \

# begin install vesta
    && bash /tmp/vst-install-ubuntu.sh \
        --nginx yes --apache yes --phpfpm no \
        --vsftpd no --proftpd no \
        --named yes --exim yes --dovecot yes \
        --spamassassin yes --clamav yes \
        --iptables yes --fail2ban yes \
        --mysql yes --postgresql yes --remi yes \
        --quota no --password MakeItSo18 \
        -y no -f \

# begin apache stuff
    && service apache2 stop && service vesta stop \

# install additional mods since 7.2 became default in the php repo
    && apt-get install -yf --no-install-recommends libapache2-mod-php7.1 libapache2-mod-php7.2 libapache2-mod-php7.3 \
        postgresql-9.6-postgis-2.5 postgresql-9.6-pgrouting postgis postgis-gui postgresql-9.6-pgaudit \
        postgresql-9.6-postgis-2.5-scripts postgresql-9.6-repack \

# install nodejs, memcached, redis-server, openvpn, mongodb, dotnet-sdk, and couchdb
    && apt-get install -yf --no-install-recommends nodejs memcached php-memcached redis-server \
        openvpn mongodb-org php-mongodb couchdb dotnet-sdk-2.2 poppler-utils ghostscript \
        libgs-dev imagemagick python3.7 \

# default python 3.7
    && ln -sf $(which python3.7) /usr/bin/python3 \

# setting upawscli, golang, and awscli
    && curl -sS "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" \
    && python3 get-pip.py \
    && pip3 install awscli \

# getting golang
    && cd /tmp \
    && curl -SL https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz -o /tmp/golang.tar.gz \
    && tar -zxf golang.tar.gz \
    && mv go /usr/local \
    && echo "\nGOROOT=/usr/local/go\nexport GOROOT\n" >> /root/.profile \

# finish cleaning up
    && rm -rf /tmp/.spam* \
    && rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean 

COPY rootfs/. /

RUN cd /tmp \
# tweaks
    && chmod +x /etc/init.d/dovecot \
    && chmod +x /etc/service/sshd/run \
    && chmod +x /etc/init.d/mongod \
    && chmod +x /etc/my_init.d/!0_startup.sh \
    && mv /sysprepz/admin/bin/vesta-*.sh /bin \

# install iconcube loader extension
    && /bin/vesta-ioncube-install.sh 7.3 \
    && /bin/vesta-ioncube-install.sh 7.1 \
    && /bin/vesta-ioncube-install.sh 7.2 \

# make sure we default fcgi and php to 7.2
    && mv /usr/bin/php-cgi /usr/bin/php-cgi-old \
    && ln -s /usr/bin/php-cgi7.2 /usr/bin/php-cgi \
    && /usr/bin/switch-php.sh "7.2" \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \

# remove phpmyadmin, phppgadmin
    && rm -rf /usr/share/phpmyadmin/* && rm -rf /usr/share/phppgadmin/* \

# install adminer
    && rm -rf /usr/share/adminer && mkdir -p /usr/share/adminer/public \
    && curl -SL https://www.adminer.org/latest.php --output /usr/share/adminer/public/index.php \

# overwrite (phpmyadmin, phppgadmin) with adminer
    && mkdir -p /etc/nginx/conf-d \
    && rsync -a /etc/nginx/conf.d/* /etc/nginx/conf-d \
    && echo 'include /etc/nginx/conf.d/dbadmin.inc;' > /etc/nginx/conf.d/phpmyadmin.inc \
    && echo 'include /etc/nginx/conf.d/dbadmin.inc;' > /etc/nginx/conf.d/phppgadmin.inc \

# activate ini
    && echo "extension=v8js.so" > /etc/php/7.1/mods-available/v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/cgi/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.1/mods-available/v8js.ini /etc/php/7.1/fpm/conf.d/20-v8js.ini \

    && echo "extension=v8js.so" > /etc/php/7.2/mods-available/v8js.ini \
    && ln -sf /etc/php/7.2/mods-available/v8js.ini /etc/php/7.2/apache2/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.2/mods-available/v8js.ini /etc/php/7.2/cli/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.2/mods-available/v8js.ini /etc/php/7.2/cgi/conf.d/20-v8js.ini \
    && ln -sf /etc/php/7.2/mods-available/v8js.ini /etc/php/7.2/fpm/conf.d/20-v8js.ini \

    && echo "extension=pcs.so" > /etc/php/7.1/mods-available/pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/apache2/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/cli/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/cgi/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.1/mods-available/pcs.ini /etc/php/7.1/fpm/conf.d/15-pcs.ini \

    && echo "extension=pcs.so" > /etc/php/7.2/mods-available/pcs.ini \
    && ln -sf /etc/php/7.2/mods-available/pcs.ini /etc/php/7.2/apache2/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.2/mods-available/pcs.ini /etc/php/7.2/cli/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.2/mods-available/pcs.ini /etc/php/7.2/cgi/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.2/mods-available/pcs.ini /etc/php/7.2/fpm/conf.d/15-pcs.ini \

    && echo "extension=pcs.so" > /etc/php/7.3/mods-available/pcs.ini \
    && ln -sf /etc/php/7.3/mods-available/pcs.ini /etc/php/7.3/apache2/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.3/mods-available/pcs.ini /etc/php/7.3/cli/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.3/mods-available/pcs.ini /etc/php/7.3/cgi/conf.d/15-pcs.ini \
    && ln -sf /etc/php/7.3/mods-available/pcs.ini /etc/php/7.3/fpm/conf.d/15-pcs.ini \

    && echo "extension=couchbase.so" > /etc/php/7.1/mods-available/couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/apache2/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/cli/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/cgi/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.1/mods-available/couchbase.ini /etc/php/7.1/fpm/conf.d/30-couchbase.ini \

    && echo "extension=couchbase.so" > /etc/php/7.2/mods-available/couchbase.ini \
    && ln -sf /etc/php/7.2/mods-available/couchbase.ini /etc/php/7.2/apache2/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.2/mods-available/couchbase.ini /etc/php/7.2/cli/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.2/mods-available/couchbase.ini /etc/php/7.2/cgi/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.2/mods-available/couchbase.ini /etc/php/7.2/fpm/conf.d/30-couchbase.ini \

    && echo "extension=couchbase.so" > /etc/php/7.3/mods-available/couchbase.ini \
    && ln -sf /etc/php/7.3/mods-available/couchbase.ini /etc/php/7.3/apache2/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.3/mods-available/couchbase.ini /etc/php/7.3/cli/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.3/mods-available/couchbase.ini /etc/php/7.3/cgi/conf.d/30-couchbase.ini \
    && ln -sf /etc/php/7.3/mods-available/couchbase.ini /etc/php/7.3/fpm/conf.d/30-couchbase.ini \

# performance tweaks
    && chmod 0755 /etc/init.d/disable-transparent-hugepages \

# increase memcache max size from 64m to 256m
    && sed -i -e "s/^\-m 64/\-m 256/g" /etc/memcached.conf \

# couchdb stuff
    && mkdir -p /var/lib/couchdb \
    && chown -R couchdb:couchdb /usr/bin/couchdb /etc/couchdb /usr/share/couchdb /var/lib/couchdb  \
    && chmod -R 0770 /usr/bin/couchdb /etc/couchdb /usr/share/couchdb /var/lib/couchdb \
 
# secure ssh
    && sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config \
    && sed -i -e "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config \

# initialize ips for docker support
    && cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
    && cd /etc/apache2/conf.d \
    && sed -i -e "s/172.*.*.*:80/127.0.0.1:80/g" * \
    && sed -i -e "s/172.*.*.*:8443/127.0.0.1:8443/g" * \
    && cd /etc/nginx/conf.d \
    && sed -i -e "s/172.*.*.*:80/127.0.0.1:80/g" * \
    && sed -i -e "s/172.*.*.*:8080/127.0.0.1:8080/g" * \
    && mv 172.*.*.*.conf 127.0.0.1.conf \
    && cd /home/admin/conf/web \
    && sed -i -e "s/172.*.*.*:80;/80;/g" * \
    && sed -i -e "s/172.*.*.*:8080/127.0.0.1:8080/g" * \

    && cd /tmp \

# postgres patch for this docker
    && sed -i -e "s/%q%u@%d '/%q%u@%d %r '/g" /etc/postgresql/9.6/main/postgresql.conf \
    && sed -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.6/main/postgresql.conf \

# php stuff - after vesta because of vesta-php installs
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/fpm/php.ini \

    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.2/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.2/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.2/cgi/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.2/fpm/php.ini \

    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.3/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.3/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.3/cgi/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.3/fpm/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/fpm/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.2/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.2/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.2/cgi/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.2/fpm/php.ini \

    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.3/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.3/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.3/cgi/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.3/fpm/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/fpm/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.2/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.2/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.2/cgi/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.2/fpm/php.ini \

    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.3/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.3/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.3/cgi/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.3/fpm/php.ini \

    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.1/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.1/fpm/php.ini \

    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.2/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.2/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.2/cgi/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.2/fpm/php.ini \

    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.3/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.3/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.3/cgi/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 300/" /etc/php/7.3/fpm/php.ini \

    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/apache2/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/cgi/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/fpm/php.ini \

    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.2/apache2/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.2/cgi/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.2/fpm/php.ini \

    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.3/apache2/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.3/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.3/cgi/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.3/fpm/php.ini \

# set same upload limit for php fcgi
    && sed -i "s/FcgidConnectTimeout 20/FcgidMaxRequestLen 629145600\n  FcgidConnectTimeout 20/" /etc/apache2/mods-available/fcgid.conf \

# sed for docker single IP
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%/\%proxy\_port\%/g" /usr/local/vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%/\%proxy\_ssl\_port\%/g" /usr/local/vesta/data/templates/web/nginx/*.stpl \
# sed to include additional conf
    && sed -i -e "s/ include \%home\%\/\%user\%\/conf\/web\/nginx\.\%domain\%/ include \%home\%\/\%user\%\/web\/\%domain\%\/private\/*.conf;\n    include \%home\%\/\%user\%\/conf\/web\/nginx\.\%domain\%/g" /usr/local/vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/ include \%home\%\/\%user\%\/conf\/web\/snginx\.\%domain\%/ include \%home\%\/\%user\%\/web\/\%domain\%\/private\/*.conf;\n    include \%home\%\/\%user\%\/conf\/web\/snginx\.\%domain\%/g" /usr/local/vesta/data/templates/web/nginx/*.stpl \
# patch for logging remote ip
    && bash /usr/local/vesta/upd/switch_rpath.sh \

# add multiple php fcgi and custom templates
    && rsync -a /sysprepz/apache2-templates/* /usr/local/vesta/data/templates/web/apache2/ \
    && rsync -a /sysprepz/nginx-templates/* /usr/local/vesta/data/templates/web/nginx/ \

# docker specific patching
    && sed -i -e "s/^if (\$dir_name/\/\/if (\$dir_name/g" /usr/local/vesta/web/list/rrd/image.php \

# increase open file limit for nginx and apache
    && echo "\n\n* soft nofile 800000\n* hard nofile 800000\n\n" >> /etc/security/limits.conf \

# patch psql9.5+ backup
    && sed -i -e "s/\-c \-\-inserts \-O \-x \-i \-f/\-\-inserts \-x \-f/g" /usr/local/vesta/func/db.sh \
    && sed -i -e "s/\-c \-\-inserts \-O \-x \-f/\-\-inserts \-x \-f/g" /usr/local/vesta/func/db.sh \
    && sed -i -e "s/dbuser/DBUSER/g" /usr/local/vesta/func/rebuild.sh \
    && sed -i -e "s/ROLE \$DBUSER/ROLE \$DBUSER WITH LOGIN/g" /usr/local/vesta/func/rebuild.sh \
    && sed -i -e "s/plsql/psql/g" /usr/local/vesta/bin/v-update-sys-rrd-pgsql \

# apache stuff
    && echo "\nServerName localhost\n" >> /etc/apache2/apache2.conf \
    && a2enmod headers && a2dismod php7.3 && a2enmod php7.2 \

# download new auto host ssl
    && curl -SL https://raw.githubusercontent.com/serghey-rodin/vesta/master/bin/v-update-host-certificate --output /usr/local/vesta/bin/v-update-host-certificate \
    && chmod +x /usr/local/vesta/bin/v-update-host-certificate \

# disable localhost redirect to bad default IP
    && sed -i -e "s/^NAT=.*/NAT=\'\'/g" /usr/local/vesta/data/ips/* \
    && service mysql stop && systemctl disable mysql \
    && service postgresql stop && systemctl disable postgresql \
    && service redis-server stop && systemctl disable redis-server \
    && service fail2ban stop && systemctl disable fail2ban \
    && service nginx stop && systemctl disable nginx \
    && service apache2 stop && systemctl disable apache2 \
    && sed -i -e "s/\/var\/lib\/mysql/\/vesta\/var\/lib\/mysql/g" /etc/mysql/my.cnf \

# for letsencrypt
    && touch /usr/local/vesta/data/queue/letsencrypt.pipe \

# setup redis like memcache
    && sed -i -e 's:^save:# save:g' \
      -e 's:^bind:# bind:g' \
      -e 's:^logfile:# logfile:' \
      -e 's:# maxmemory \(.*\)$:maxmemory 256mb:' \
      -e 's:# maxmemory-policy \(.*\)$:maxmemory-policy allkeys-lru:' \
      /etc/redis/redis.conf \
    && sed -i -e "s/\/etc\/redis/\/vesta\/etc\/redis/g" /etc/init.d/redis-server \

# disable php*admin and roundcube by default, backup the config first - see README.md    
    && mkdir -p /etc/apache2/conf-d \
    && rsync -a /etc/apache2/conf.d/* /etc/apache2/conf-d \
    && rm -f /etc/apache2/conf.d/php*.conf \
    && rm -f /etc/apache2/conf.d/roundcube.conf \

# begin folder redirections
    && mkdir -p /vesta-start/etc \
    && mkdir -p /vesta-start/var/lib \
    && mkdir -p /vesta-start/local \

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

    && mv /etc/spamassassin   /vesta-start/etc/spamassassin \
    && rm -rf /etc/spamassassin \
    && ln -s /vesta/etc/spamassassin /etc/spamassassin \

    && mv /etc/mail   /vesta-start/etc/mail \
    && rm -rf /etc/mail \
    && ln -s /vesta/etc/mail /etc/mail \

    && mv /etc/redis   /vesta-start/etc/redis \
    && rm -rf /etc/redis \
    && ln -s /vesta/etc/redis /etc/redis \

    && mkdir -p /var/lib/mongodb \
    && chown -R mongodb:mongodb /var/lib/mongodb \
    && mv /var/lib/mongodb /vesta-start/var/lib/mongodb \
    && rm -rf /var/lib/mongodb \
    && ln -s /vesta/var/lib/mongodb /var/lib/mongodb \

    && mkdir -p /var/lib/redis \
    && chown -R redis:redis /var/lib/redis \
    && mv /var/lib/redis /vesta-start/var/lib/redis \
    && rm -rf /var/lib/redis \
    && ln -s /vesta/var/lib/redis /var/lib/redis \

    && mv /etc/awstats /vesta-start/etc/awstats \
    && rm -rf /etc/awstats \
    && ln -s /vesta/etc/awstats /etc/awstats \

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

    && mv /etc/couchdb /vesta-start/etc/couchdb \
    && rm -rf /etc/couchdb \
    && ln -s /vesta/etc/couchdb /etc/couchdb \

    && mv /var/lib/couchdb /vesta-start/var/lib/couchdb \
    && rm -rf /var/lib/couchdb \
    && ln -s /vesta/var/lib/couchdb /var/lib/couchdb \

    && mkdir -p /sysprepz/home \
    && rsync -a /home/* /sysprepz/home \
    && mv /sysprepz/admin/bin /sysprepz/home/admin \
    && chown -R admin:admin /sysprepz/home/admin/bin \

    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions \

# fix roundcube error log permission
    && touch /vesta-start/var/log/roundcube/errors \
    && chown -R www-data:www-data /vesta-start/var/log/roundcube \
    && chmod 775 /vesta-start/var/log/roundcube/errors \

# pagespeed stuff
    && mkdir -p /var/ngx_pagespeed_cache \
    && chmod 755 /var/ngx_pagespeed_cache \
    && chown www-data:www-data /var/ngx_pagespeed_cache \

# finish cleaning up
    && rm -rf /backup/.etc \
    && rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean 

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 143 443 465 587 993 995 1194 3000 3306 5432 5984 6379 8083 10022 11211 27017
