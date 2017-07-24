#!/bin/sh

# only if you run in privileged mode
# if [[ -f /etc/fail2ban/jail.new ]]; then
#     mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local-bak
#     mv /etc/fail2ban/jail.new /etc/fail2ban/jail.local
# fi

# re-enable phpmyadmin and phppgadmin
# rsync -a /etc/apache2/conf-d/php*.conf /etc/apache2/conf.d

# required startup and of course vesta
cd /etc/init.d/
./disable-transparent-hugepages defaults \
&& ./apache2 start \
&& ./mysql start \
&& ./postgresql start \
&& ./nginx start \
&& ./vesta start

# && ./exim4 start \
# && ./dovecot start \
# && ./clamav-daemon start \
# && ./spamassassin start \
# && ./php7.0-fpm start \
# && ./fail2ban start \ # -- only if you run with: --cap-add=NET_ADMIN --cap-add=NET_RAW
