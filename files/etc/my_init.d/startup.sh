#!/bin/bash

export TERM=xterm

if [ -z "`ls /vesta --hide='lost+found'`" ]
then
    rsync -a /vesta-start/* /vesta
    rsync -a /home-bak/* /home

    # make default template work with any IP, we want this for Docker
    sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/default.tpl
    sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /vesta/local/vesta/data/templates/web/nginx/default.stpl
    
    sed -i -e "s/proxy_set_header X-Real-IP \$remote_addr\;\n      proxy_pass/proxy_pass/g" /vesta/local/vesta/data/templates/web/nginx/default.tpl
    sed -i -e "s/proxy_set_header X-Real-IP \$remote_addr\;\n      proxy_pass/proxy_pass/g" /vesta/local/vesta/data/templates/web/nginx/default.stpl

    # disable localhost redirect to bad default IP
    sed -i -e "s/^NAT=.*/NAT=\'\'/g" /vesta/local/vesta/data/ips/127.0.0.1
fi

# starting Vesta
cd /etc/init.d/ \
&& ./vesta start \
&& ./mysql start \
&& ./nginx start \
&& ./exim4 start \
&& ./dovecot start \
&& ./apache2 start \
&& ./postgresql start
# && ./clamav-daemon start \
# && ./spamassassin start \
# && ./php7.0-fpm start \
