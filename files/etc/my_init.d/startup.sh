#!/bin/bash

export TERM=xterm

if [ -z "`ls /vesta --hide='lost+found'`" ]
then
    rsync -a /vesta-start/* /vesta
    rsync -a /home-bak/* /home

    # make default template work with any IP, we want this for Docker
    sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/*.tpl
    sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/*.stpl
    sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/php-fpm/*.tpl
    sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/php-fpm/*.stpl
    
    bash /usr/local/vesta/upd/switch_rpath.sh

    # patch default website
    cd "$(dirname "$(find /home/admin/web/* -type d -name public_html)")" \
    && sed -i -e "s/vestacp/nginx/g" public_html/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_html/index.html \
    && sed -i -e "s/vestacp/nginx/g" public_shtml/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_shtml/index.html \
    
    # disable localhost redirect to bad default IP
    sed -i -e "s/^NAT=.*/NAT=\'\'/g" /vesta/local/vesta/data/ips/127.0.0.1

    # increase memcache max size from 64m to 2g
    sed -i -e "s/^\-m 64/\-m 2048/g" /vesta/etc/memcached.conf

    # remove rlimit in docker nginx
    sed -i -e "s/^worker_rlimit_nofile    65535;//g" /vesta/etc/nginx/nginx.conf

    # vesta monkey patching
    # patch psql9.5 backup
    sed -i -e "s/\-x \-i \-f/\-x \-f/g" /vesta/local/vesta/func/db.sh

    # https://github.com/serghey-rodin/vesta/issues/1009
    sed -i -e "s/unzip/unzip \-o/g" /vesta/local/vesta/bin/v-extract-fs-archive

    touch ~/.profile \
    && cat ~/.bash_profile >> ~/.profile \
    && rm -f ~/.bash_profile

    echo $'\nServerName localhost\n' >> /etc/apache2/apache2.conf

    sed -i -e "s/^ULIMIT_MAX_FILES=.*/ULIMIT_MAX_FILES=/g" /usr/sbin/apache2ctl
fi

# starting Vesta
bash /vesta/my-startup.sh
