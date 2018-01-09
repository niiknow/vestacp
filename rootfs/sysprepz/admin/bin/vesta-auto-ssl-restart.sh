#!/bin/bash

# get environment variables
source /etc/container_environment.sh

# Includes
source /usr/local/vesta/func/main.sh
source /usr/local/vesta/func/ip.sh
source /usr/local/vesta/conf/vesta.conf

# wait for things to completely moved into directory
sleep 5

# Restart exim, dovecot & vesta
/usr/local/vesta/bin/v-restart-mail
/usr/local/vesta/bin/v-restart-service dovecot
/usr/local/vesta/bin/v-restart-service vesta

exit 0
