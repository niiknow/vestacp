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
    sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/php-fpm*.stpl
    
    bash /usr/local/vesta/upd/switch_rpath.sh
    
    # patch psql9.5 backup
    sed -i -e "s/\-x \-i \-f/\-x \-f/g" /vesta/local/vesta/func/db.sh

    # patch default website
    cd "$(dirname "$(find /home/admin/web/* -type d -name public_html)")" \
    && sed -i -e "s/vestacp/nginx/g" public_html/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_html/index.html \
    && sed -i -e "s/vestacp/nginx/g" public_shtml/index.html \
    && sed -i -e "s/VESTA/NGINX/g" public_shtml/index.html \
    
    # disable localhost redirect to bad default IP
    sed -i -e "s/^NAT=.*/NAT=\'\'/g" /vesta/local/vesta/data/ips/127.0.0.1

fi

# starting Vesta
bash /vesta/my-startup.sh
