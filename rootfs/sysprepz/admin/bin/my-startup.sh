#!/bin/sh

# re-enable phpmyadmin and phppgadmin
# rsync -a /etc/apache2/conf-d/php*.conf /etc/apache2/conf.d

# required startup and of course vesta
cd /etc/init.d/
./disable-transparent-hugepages defaults

# the 5 services below are enabled to support mininum default backup job
./apache2 start \
&& ./mysql start

# delete defult postgres admindb if not use, then comment out the line below
./postgresql start \
&& ./nginx start \
&& ./vesta start

# && ./exim4 start \
# && ./dovecot start \
# && ./clamav-daemon start \
# && ./spamassassin start \
# && ./php7.0-fpm start \
# && ./fail2ban start \ # -- only if you run with: --cap-add=NET_ADMIN --cap-add=NET_RAW
