#!/bin/sh

# required startup and of course vesta
cd /etc/init.d/
./disable-transparent-hugepages defaults

# the 5 services below are enabled to support mininum default backup job
./apache2 start
./mysql start

# delete old php-fpm running file on restart
rm -f /var/run/vesta*.sock
rm -f /var/run/vesta*.pid
rm -f /var/run/nginx.pid

# delete defult postgres admindb if not use, then comment out the line below
./postgresql start
./vesta start

./php7.2-fpm start
./php7.3-fpm start
./nginx start

# ./fail2ban start \ # -- only if you run with: --cap-add=NET_ADMIN --cap-add=NET_RAW
# other services (exim4, dovecot, clamav-daemon, spamassassin, couchdb, mongodb)
