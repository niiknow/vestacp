#!/bin/bash
# this script create a service dir for a specified user

# get environment variables
source /etc/container_environment.sh

VESTA_PATH='/usr/local/vesta'
user="$1"

# only run if user has a value
if [ -n "$user" ]; then
	if [ ! -d "/home/$user" ]; then
		echo "[e] $user or home directory for user does not exists, exiting..."
  		exit 1
	fi
	mkdir -p /etc/service/runsvdir-$user
	mkdir -p /home/$user/service
	chown -R $user:$user /home/$user/service

	printf "#!/bin/sh\n\nexec 2>&1\nexec chpst -u$user runsvdir /home/$user/service" > /etc/service/runsvdir-$user/run
	chmod +x /etc/service/runsvdir-$user/run
else
	echo "[?] $0 username"
fi
