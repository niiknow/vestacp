#!/bin/bash
# this file is use to update between different
# of vesta within this docker panel
rsync --update -raz --progress --exclude 'data' --exclude 'log' --exclude 'conf' --exclude 'nginx' /vesta-start/local/vesta /usr/local/vesta

rsync --update -raz --progress /vesta-start/local/vesta/data/templates /usr/local/vesta/data/templates

rsync --update -raz --progress --exclude 'conf.d' /vesta-start/etc/nginx /etc/nginx
