#!/bin/bash
# this file is use to update between different
# of vesta within this docker panel
rsync --update -ahp --progress --exclude 'data' --exclude 'log' --exclude 'conf' --exclude 'nginx' /vesta-start/local/vesta/ /usr/local/vesta/

rsync --update -ahp --progress /vesta-start/local/vesta/data/templates/ /usr/local/vesta/data/templates/

# comment out -- too much overriding to run
# rsync --update -ahp --progress --exclude 'conf.d' --exclude 'mysql' vesta-start/etc/ /etc/

# update php conf
rm -rf /vesta/etc/php/*
rsync --update -ahp --progress /vesta-start/etc/php/ /vesta/etc/php/

if [ ! -d "/var/lib/postgresql/9.6/" ]; then
    echo "[i] add postgresql 9.6"
    rsync --update -ahp /vesta-start/var/lib/postgresql/9.6/ /vesta/var/lib/postgresql/9.6/
    rsync --update -ahp /vesta-start/etc/postgresql/9.6/ /vesta/etc/postgresql/9.6/
fi

# restart vesta after update
rm -f /var/run/vesta-php.sock
service vesta restart