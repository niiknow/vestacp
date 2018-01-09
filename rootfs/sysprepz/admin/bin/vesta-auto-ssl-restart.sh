#!/bin/bash

# get environment variables
source /etc/container_environment.sh

# Includes
source $VESTA/func/main.sh
source $VESTA/func/ip.sh
source $VESTA/conf/vesta.conf

# wait for things to completely moved into directory
sleep 5

# Restart exim, dovecot & vesta
v-restart-mail
v-restart-service dovecot
v-restart-service vesta
