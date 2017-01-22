FROM niiknow/docker-hostingbase:0.5.10

MAINTAINER friends@niiknow.org

ENV DEBIAN_FRONTEND=noninteractive \
    VESTA=/usr/local/vesta \
    DOTNET_VERSION=1.1.0 \
    DOTNET_DOWNLOAD_URL=https://dotnetcli.blob.core.windows.net/dotnet/release/1.1.0/Binaries/$DOTNET_VERSION/dotnet-debian-x64.$DOTNET_VERSION.tar.gz \
    GOLANG_VERSION=1.7.4 \
    GOLANG_DOWNLOAD_URL=https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz

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
    && echo -e "\n\GOROOT=/usr/local/go\nexport GOROOT\n" >> /root/.profile

# install php
RUN \
    cd /tmp \
    && pecl install v8js \

    && apt-get install -yq php7.0-mbstring php7.0-cgi php7.0-cli php7.0-dev php7.0-geoip php7.0-common php7.0-xmlrpc \
        php7.0-curl php7.0-enchant php7.0-imap php7.0-xsl php7.0-mysql php7.0-mysqlnd php7.0-pspell php7.0-gd \
        php7.0-tidy php7.0-opcache php7.0-json php7.0-bz2 php7.0-pgsql php7.0-mcrypt php7.0-readline  \
        php7.0-intl php7.0-sqlite3 php7.0-ldap php7.0-xml php7.0-redis php7.0-imagick php7.0-zip \

    && apt-get install -yq php7.1-mbstring php7.1-cgi php7.1-cli php7.1-dev php7.1-geoip php7.1-common php7.1-xmlrpc \
        php7.1-curl php7.1-enchant php7.1-imap php7.1-xsl php7.1-mysql php7.1-mysqlnd php7.1-pspell php7.1-gd \
        php7.1-tidy php7.1-opcache php7.1-json php7.1-bz2 php7.1-pgsql php7.1-mcrypt php7.1-readline \
        php7.1-intl php7.1-sqlite3 php7.1-ldap php7.1-xml php7.1-redis php7.1-imagick php7.1-zip

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
    bash /sysprepz/configure.sh

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 5984 6379 8083 10022 11211 27017
