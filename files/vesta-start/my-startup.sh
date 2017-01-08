#!/bin/bash
# restore current users
if [[ -f /vesta/etc-bak/passwd ]]; then
	# restore users
	rsync -a /vesta/etc-bak/passwd /etc/passwd
	rsync -a /vesta/etc-bak/shadow /etc/shadow
	rsync -a /vesta/etc-bak/gshadow /etc/gshadow
	rsync -a /vesta/etc-bak/group /etc/group
fi	

# fix roundcube error log permission
touch /vesta/var/log/roundcube/errors
chmod 775 /vesta/var/log/roundcube/errors

# you control your startup in this file
cd /etc/init.d/ \
&& ./vesta start \
&& ./mysql start \
&& ./nginx start \
&& ./exim4 start \
&& ./dovecot start \
&& ./apache2 start \
&& ./postgresql start
# && ./clamav-daemon start \
# && ./spamassassin start \
# && ./php7.0-fpm start \
