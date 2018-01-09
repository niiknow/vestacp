#!/bin/bash

# get environment variables
source /etc/container_environment.sh

VESTA_PATH='/usr/local/vesta'
hostname="$VESTA_DOMAIN"
user='admin'

# only run if hostname has a value
if [ -n "$hostname" ]; then

    # too often, user did not setup DNS host to IP correctly, so we should validate first
    # issue is easier fix by the user than getting blocked by Letsencrypt server
    #
    # validate that the hostname matches the IP

    # get the ip
    DOMAINIP=$( dig +short ${hostname}  | grep -v "\.$" | head -n 1 )

    # only run if the variable is empty
    if [[ -z "$MYIP" ]]; then
        MYIP=$( dig +short myip.opendns.com @resolver1.opendns.com | grep -v "\.$" | head -n 1 )
    fi

    # create the website under admin for Letsencrypt SSL
    if [[ $DOMAINIP != $MYIP ]]; then
        echo "[err] Domain '$hostname' IP '$DOMAINIP' does not match Host IP '$MYIP'"

        # only error message to prevent error in app startup
        exit 0
    fi

    # wait for any web service to start first (nginx, apache, vesta, etc...)
    # since letsencrypt need to hit and validate
    sleep 5

    cd /usr/local/vesta/bin
    /usr/local/vesta/bin/v-update-host-certificate $user $hostname
else
    echo "[i] vesta-auto-ssl exit due to empty VESTA_DOMAIN variable"
fi