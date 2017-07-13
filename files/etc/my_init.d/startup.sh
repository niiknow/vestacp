#!/bin/bash

export TERM=xterm

if [ -z "`ls /vesta --hide='lost+found'`" ]
then
    rsync -a /vesta-start/* /vesta
    rsync -a /sysprepz/home/* /home    
fi

# restore current users
if [[ -f /backup/.etc/passwd ]]; then
	# restore users
	rsync -a /backup/.etc/passwd /etc/passwd
	rsync -a /backup/.etc/shadow /etc/shadow
	rsync -a /backup/.etc/gshadow /etc/gshadow
	rsync -a /backup/.etc/group /etc/group
fi


chown www-data:www-data /var/ngx_pagespeed_cache
chmod 750 /var/ngx_pagespeed_cache


if [ -f /etc/nginx/nginx.new ]; then
   mv /etc/nginx/nginx.conf /etc/nginx/nginx.old
   mv /etc/nginx/nginx.new /etc/nginx/nginx.conf
fi


# start incron after restore
cd /etc/init.d/
./incron start

# starting Vesta
bash /home/admin/bin/my-startup.sh
