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
    && /tmp/install/index.sh

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 6379 8083 10022 11211 27017
