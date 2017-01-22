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

# starting Vesta
bash /home/admin/bin/my-startup.sh
