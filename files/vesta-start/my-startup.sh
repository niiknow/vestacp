#!/bin/bash
# restore current users
if [[ -f /vesta/etc-bak/passwd ]]; then
	# restore users
	rsync -a /vesta/etc-bak/passwd /etc/passwd
	rsync -a /vesta/etc-bak/shadow /etc/shadow
	rsync -a /vesta/etc-bak/gshadow /etc/gshadow
	rsync -a /vesta/etc-bak/group /etc/group
fi	

# only if you run in privileged mode
# if [[ -f /etc/fail2ban/jail.new ]]; then
#     mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local-bak
#     mv /etc/fail2ban/jail.new /etc/fail2ban/jail.local
# fi

# re-enable phpmyadmin and phppgadmin
# rsync -a /vesta-start/etc-bak/apache2/conf.d/php*.conf /etc/apache2/conf.d

# fix roundcube error log permission
touch /vesta/var/log/roundcube/errors
chown www-data:www-data /vesta/var/log/roundcube
chown www-data:www-data /vesta/var/log/roundcube/errors
chmod 775 /vesta/var/log/roundcube/errors

# you control your startup in this file
cd /etc/init.d/ \
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
# && ./fail2ban start \ # -- only if you run in privileged mode
