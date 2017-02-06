#!/bin/bash

export TERM=xterm

if [ -z "`ls /vesta --hide='lost+found'`" ]
then
    rsync -a /vesta-start/* /vesta
    rsync -a /sysprepz/home/* /home
    rsync -a /sysprepz/admin/bin /home/admin
    
    chown admin:admin /home/admin/bin -R

    # fix roundcube error log permission
    touch /vesta/var/log/roundcube/errors
    chown www-data:www-data /vesta/var/log/roundcube
    chown www-data:www-data /vesta/var/log/roundcube/errors
    chmod 775 /vesta/var/log/roundcube/errors
fi

# restore current users
if [[ -f /backup/.etc/passwd ]]; then
	# restore users
	rsync -a /backup/.etc/passwd /etc/passwd
	rsync -a /backup/.etc/shadow /etc/shadow
	rsync -a /backup/.etc/gshadow /etc/gshadow
	rsync -a /backup/.etc/group /etc/group
fi

# start incron after restore
cd /etc/init.d/
./incron start

# starting Vesta
bash /home/admin/bin/my-startup.sh
