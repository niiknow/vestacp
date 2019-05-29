#!/bin/bash

export TERM=xterm
MYPASS=

if [ ! -f /home/admin/bin/my-startup.sh ]; then
    echo "[i] running for the 1st time"
    rsync --update -raz /vesta-start/* /vesta
    rsync --update -raz /sysprepz/home/* /home
# work around for AUFS bug
# as per https://github.com/docker/docker/issues/783#issuecomment-56013588
    mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private
# save some bytes, you can do it later
#    rm -rf /sysprepz
#    rm -rf /vesta-start
fi

# restore current users
if [ -f /backup/.etc/passwd ]; then
    echo "[i] restoring existing users"
	# restore users
	rsync -a /backup/.etc/passwd /etc/passwd
	rsync -a /backup/.etc/shadow /etc/shadow
	rsync -a /backup/.etc/gshadow /etc/gshadow
	rsync -a /backup/.etc/group /etc/group
fi

chown www-data:www-data /var/ngx_pagespeed_cache
chmod 750 /var/ngx_pagespeed_cache

if [ -f /etc/nginx/nginx.new ]; then
    echo "[i] init nginx"
	mv /etc/nginx/nginx.conf /etc/nginx/nginx.old
	mv /etc/nginx/nginx.new /etc/nginx/nginx.conf
fi

if [ -f /etc/fail2ban/jail.new ]; then
    echo "[i] init fail2ban"
    mv /etc/fail2ban/jail.local /etc/fail2ban/jail-local.bak
    mv /etc/fail2ban/jail.new /etc/fail2ban/jail.local
fi

# make sure runit services are running across restart
find /etc/service/ -name "down" -exec rm -rf {} \;

# make sure mysql log is available for fail2ban
touch /var/log/mysql/error.log

# starting Vesta
if [ -f /home/admin/bin/my-startup.sh ]; then
    echo "[i] running /home/admin/bin/my-startup.sh"
    bash /home/admin/bin/my-startup.sh
else
    echo "[err] unable to locate /home/admin/bin/my-startup.sh"
fi

# auto ssl on start
if [ -f /bin/vesta-auto-ssl.sh ]; then
    echo "[i] running /bin/vesta-auto-ssl.sh"
    bash /bin/vesta-auto-ssl.sh
fi

find /home/admin/web -maxdepth 2 -type d -name "private" -exec sh -c 'echo "include /etc/nginx/conf.d/dbadmin.inc;" > $1/dbadmin.conf ' sh {} ';'

