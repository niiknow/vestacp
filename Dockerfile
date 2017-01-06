FROM phusion/baseimage

MAINTAINER friends@niiknow.org

ENV VESTA /usr/local/vesta \
    DEBIAN_FRONTEND noninteractive \

RUN apt-get -o Acquire::GzipIndexes=false update

# start
RUN apt-get update && apt-get -y upgrade \
    && apt-get -y install wget curl git unzip nano vim rsync sudo tar \
       apt-utils software-properties-common build-essential \
       python-dev python-pip libxml2-dev libxslt1-dev zlib1g-dev libffi-dev libssl-dev \
       libmagickwand-dev imagemagick perl netcat mcrypt pwgen memcached \
       tcl redis-server netcat openssl libpcre3 dnsmasq procps

RUN dpkg --configure -a \

# setup imagick and python
    && curl -s -o /tmp/python-support_1.0.15_all.deb https://launchpadlibrarian.net/109052632/python-support_1.0.15_all.deb \
    && dpkg -i /tmp/python-support_1.0.15_all.deb \

# setting up aws-cli and s3cmd
    && wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | apt-key add - \
    && wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 \
    && echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.2 main" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list \
    && apt-get update && apt-get -y upgrade \
    && apt-get -y install s3cmd mongodb-org-tools \
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && pip install awscli

# install VestaCP
RUN dpkg --configure -a \
    && apt-get update && apt-get -yq upgrade && apt-get install -yf \
    && curl -s -o /tmp/vst-install-ubuntu.sh https://vestacp.com/pub/vst-install-ubuntu.sh \
    && bash /tmp/vst-install-ubuntu.sh \
    --nginx yes --apache yes --phpfpm no \
    --vsftpd no --proftpd no \
    --exim yes --dovecot yes --spamassassin yes --clamav yes --named yes \
    --iptables no --fail2ban no \
    --mysql yes --postgresql yes --remi yes \
    --quota no --password MakeDonaldDrumpfAgain2017 \
    -y no -f \
    && apt-get clean

# install composer, nodejs, fix exim4 issue starting on ubuntu
RUN curl -sS https://getcomposer.org/installer | php -- --version=1.3.0 --install-dir=/usr/local/bin --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - \
    && apt-get update && apt-get -y upgrade \
    && apt-get install -y exim4-daemon-heavy \
    && apt-get install -y nodejs php-memcached \
    && npm install --quiet -g gulp express bower mocha karma-cli pm2 && npm cache clean \
    && ln -sf /usr/bin/nodejs /bin/node \
    && dpkg --configure -a \
    && apt-get -yf autoremove \
    && apt-get clean

ADD ./files /
RUN chmod +x /etc/init.d/dovecot \
    && chmod +x /etc/my_init.d/startup.sh \

# initialize ips for docker support
    && cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
    && cd /etc/apache2/conf.d && sed -i -- 's/172.*.*.*:80/127.0.0.1:80/g' * && sed -i -- 's/172.*.*.*:8443/127.0.0.1:8443/g' * \
    && cd /etc/nginx/conf.d && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \
    && cd /home/admin/conf/web && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \
    && rm -f /etc/service/sshd/down \
    && /etc/my_init.d/00_regen_ssh_host_keys.sh \

# redirect sql data folder
    && service mysql stop \
    && service postgresql stop \
    && service redis-server stop \
    && sed -i -e "s/\/var\/lib\/mysql/\/vesta\/var\/mysql/g" /etc/mysql/my.cnf \
    && sed -i -e "s/dir \./dir \/vesta\/redis\/db/g" /etc/redis/redis.conf \

# the rest
    && mkdir /vesta-start \
    && mkdir /vesta-start/etc \
    && mkdir /vesta-start/var \
    && mkdir /vesta-start/local \
    && mkdir -p /vesta-start/redis/db \

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

    && mv /etc/shadow /vesta-start/etc/shadow \
    && rm -rf /etc/shadow \
    && ln -s /vesta/etc/shadow /etc/shadow \

    && mv /etc/bind /vesta-start/etc/bind \
    && rm -rf /etc/bind \
    && ln -s /vesta/etc/bind /etc/bind \

    && mv /etc/profile /vesta-start/etc/profile \
    && rm -rf /etc/profile \
    && ln -s /vesta/etc/profile /etc/profile \

    && mv /var/log /vesta-start/var/log \
    && rm -rf /var/log \
    && ln -s /vesta/var/log /var/log \

# home folder
    && mkdir -p /home-bak \
    && rsync -a /home/* /home-bak \
    && mkdir -p /etc/my_init.d \

# vesta session
    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions

# php stuff
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 520M/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 520M/" /vesta-start/etc/php/7.0/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 520M/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 520M/" /vesta-start/etc/php/7.0/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /vesta-start/etc/php/7.0/apache2/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /vesta-start/etc/php/7.0/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /vesta-start/etc/php/7.0/cli/php.ini 


VOLUME ["/vesta", "/home"]

EXPOSE 22 25 53 54 80 110 443 993 3306 5432 8083
