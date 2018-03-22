#!/bin/bash
# this file is use to update between different
# of vesta within this docker panel
rsync --update -raz --progress --exclude 'data' --exclude 'log' --exclude 'conf' --exclude 'nginx' /vesta-start/local/vesta /usr/local/vesta

rsync --update -raz --progress /vesta-start/local/vesta/data/templates /usr/local/vesta/data/templates

rsync --update -raz --progress --exclude 'conf.d' /vesta-start/etc/nginx /etc/nginx

# update php conf
rm -rf /vesta/etc/php/*
rsync --update -raz --progress /vesta-start/etc/php/ /vesta/etc/php/

if [ ! -d "/var/lib/postgresql/9.6/" ]; then
    echo "[i] add postgresql 9.6"
    rsync --update -raz /vesta-start/var/lib/postgresql/9.6/* /vesta/var/lib/postgresql/9.6
    rsync --update -raz /vesta-start/etc/postgresql/9.6/* /vesta/etc/postgresql/9.6
fi
