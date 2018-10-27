#!/bin/bash

# get environment variables
source /etc/container_environment.sh

VESTA_PATH='/usr/local/vesta'
domain=`/bin/hostname --fqdn`
user='admin'

# only run if hostname is valid, regex check if it has a period
# default docker installation is some random string
if [[ $domain == *[\.]* ]]; then

    # too often, user did not setup DNS host to IP correctly, so we should validate first
    # issue is easier fix by the user than getting blocked by Letsencrypt server
    #
    # validate that the domain matches the IP

    # get the ip
    DOMAINIP=$( dig +short ${domain}  | grep -v "\.$" | head -n 1 )

    # only run if the variable is empty
    if [[ -z "$MYIP" ]]; then
        MYIP=$( dig +short myip.opendns.com @resolver1.opendns.com | grep -v "\.$" | head -n 1 )
    fi

    # create the website under admin for Letsencrypt SSL
    if [[ $DOMAINIP != $MYIP ]]; then
        echo "[err] Domain '$domain' IP '$DOMAINIP' does not match Host IP '$MYIP'"

        # only error message to prevent error in app startup
        exit 0
    fi

    # wait for any web service to start first (nginx, apache, vesta, etc...)
    # since letsencrypt need to hit and validate
    sleep 5

    cert_src="/home/${user}/conf/web/ssl.${domain}.pem"
    key_src="/home/${user}/conf/web/ssl.${domain}.key"

    cert_dst="/usr/local/vesta/ssl/certificate.crt"
    key_dst="/usr/local/vesta/ssl/certificate.key"

    if [ ! -f "/usr/local/vesta/data/users/$user/ssl/le.conf" ]; then
        tldomain=`echo $domain | grep -oP '[^.]+\.+[^.]+$'`
        echo "[i] Creating letsencrypt '$user' with email '$user@$tldomain'"

        $VESTA_PATH/bin/v-add-letsencrypt-user "$user" "$user@$tldomain"
    fi

    if [ ! -d "/home/$user/web/$domain/" ]; then
        echo "[i] Creating website '$domain' for '$user'"

        $VESTA_PATH/bin/v-add-web-domain "$user" "$domain" '127.0.0.1' 'no' 'none' ''
    fi

    # if no letsencrypt cert, create one
    if [ ! -f "$cert_src" ]; then
        echo "[i] Creating cert for '$user' domain '$domain'"

        $VESTA_PATH/bin/v-add-letsencrypt-domain "$user" "$domain" '' 'yes'

        # wait for letsencrypt to complete
        # a better check would be for the existence of $cert_src with x retries
        sleep 5
    fi

    if [ ! -f "$cert_src" ]; then
        echo "[err] cert not found '$cert_src'"

        # only error message to prevent error in app startup
        exit 0
    fi

    if ! cmp -s $cert_dst $cert_src
    then
        # backup the old cert
        cp -fn $cert_dst "$cert_dst.bak"
        cp -fn $key_dst "$key_dst.bak"

        # link the new cert
        ln -sf $cert_src $cert_dst
        ln -sf $key_src $key_dst

        # Change Permission
        chown root:mail $cert_dst
        chown root:mail $key_dst

        # Let the user restart the service by themself
        # service vesta restart &> /dev/null
        # service exim4 restart &> /dev/null
        echo "[i] Cert file successfullly swapped out.  Please restart docker or vesta, apache2, nginx, and exim4."
    fi
else
    echo "[i] vesta-auto-ssl exit due to invalid/default docker hostname: $domain"
fi