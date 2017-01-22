FROM niiknow/docker-hostingbase:0.5.3

MAINTAINER friends@niiknow.org

ENV DEBIAN_FRONTEND=noninteractive \
    VESTA=/usr/local/vesta

RUN \
    curl -sS https://getcomposer.org/installer | php -- --version=1.3.1 --install-dir=/usr/local/bin --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - \

    && apt-get update && apt-get -y upgrade \
    && apt-get install -y mongodb-org nodejs php-memcached php-mongodb \
    && npm install --quiet -g gulp express bower pm2 webpack webpack-dev-server karma protractor typings typescript \
    && npm cache clean \
    && ln -sf "$(which nodejs)" /usr/bin/node

ADD ./files /
RUN \
    cd /tmp \
    && chmod +x /tmp/install/*.sh \
    && bash /tmp/install/php.sh \
    && bash /tmp/install/vesta.sh

# cleanup
RUN rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean \

# Monkey patching for docker
# make default template work with any IP, we want this for Docker
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.stpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.stpl \

    && bash /usr/local/vesta/upd/switch_rpath.sh \

# patch default website
    && cd "$(dirname "$(find /home/admin/web/* -type d -name public_html)")" \
    && sed -i -e "s/vestacp/nginx/g" public_html/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_html/index.html \
    && sed -i -e "s/vestacp/nginx/g" public_shtml/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_shtml/index.html \

# disable localhost redirect to bad default IP
    && sed -i -e "s/^NAT=.*/NAT=\'\'/g" /usr/local/vesta/data/ips/127.0.0.1 \

# increase memcache max size from 64m to 2g
    && sed -i -e "s/^\-m 64/\-m 2048/g" /usr/etc/memcached.conf \

# remove rlimit in docker nginx
    && sed -i -e "s/^worker_rlimit_nofile    65535;//g" /etc/nginx/nginx.conf \

# vesta monkey patching
# patch psql9.5 backup
    && sed -i -e "s/\-x \-i \-f/\-x \-f/g" /usr/local/vesta/func/db.sh \

# https://github.com/serghey-rodin/vesta/issues/1009
    && sed -i -e "s/unzip/unzip \-o/g" /usr/local/vesta/bin/v-extract-fs-archive \

    && echo $'\nServerName localhost\n' >> /etc/apache2/apache2.conf \
    && sed -i -e "s/^ULIMIT_MAX_FILES=.*/ULIMIT_MAX_FILES=/g" /usr/sbin/apache2ctl \

    rm -rf /tmp/*

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 6379 8083 10022 11211 27017
