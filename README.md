# VestaCP
The ultimate control panel with docker (thanks lagun4ik for a great start)

What's included?
* ubuntu 16.04 lts + Vesta 0.9.8-17
* nginx (proxy) -> apache2 -> php7.0 - high performance and flexible implementation
* ssh/sftp, letsencrypt, memcached, redis, MariaDB 10.1, postgresql 9.5, nodejs 6.x, golang 1.7.5, openvpn, mongodb, couchdb
* folder redirection for data persistence and automatic daily backup provided by VestaCP
* DNS, named, dovecot, spamassassin, clamav, fail2ban, etc... -- disabled by default

Run this image:

mkdir -p /opt/vestacp/{vesta,home,backup}

docker run -d --restart=always -p 2222:22 -p 80:80 -p 443:443 -p 3306:3306 -p 5432:5432 -p 8083:8083 -v /opt/vestacp/vesta:/vesta -v /opt/vestacp/home:/home -v /opt/vestacp/data:/backup niiknow/vestacp

## Volumes
/vesta  -- configurations
/home   -- users data
/backup -- users backup

## Authorization
Login: admin Password: MakeItSo17

## SSH for FTP
Use SFTP instead of FTP on the 2222 port.  Disable ssh if you don't really need it and use the Vesta FileManager plugin.

## Welcome to Hosting in 2017!
Below are scenarios that work great with this docker.

### 1) WordPress Site in 2017
mkdir -p /opt/vestacp/{vesta,home,backup}

docker run -d --restart=always -p 80:80 -p 443:443 -p 8083:8083 -v /opt/vestacp/vesta:/vesta -v /opt/vestacp/home:/home -v /opt/vestacp/backup:/backup niiknow/vestacp

1. Change admin password
2. Modify my-startup.sh and comment out postgresql start.  Install your wordpress site through VestaCP with FileManager.
3. Setup Letsencrypt to help with security and SEO.  Welcome to 2017!!!
4. Setup cron job to sync /backup folder with aws s3 for remote backup and you're good to go.

### 2) mysql server
mkdir -p /opt/vestacp/{vesta,home,backup}

docker run -d --restart=always -p 4321:3306 -p 8083:8083 -v /opt/vestacp/vesta:/vesta -v /opt/vestacp/home:/home -v /opt/vestacp/backup:/backup niiknow/vestacp

1. Change admin password.
2. Modify my-startup.sh and comment out postgresql start.
3. Connect securely to your MYSQL to any port as in example above mapping to 4321 on docker host.  Welcome to 2017!!!  Your backup is automatically done through VestaCP.
4. Setup cron job to sync /backup folder with aws s3 for remote backup and you're good to go.

### 3) postgresql server
mkdir -p /opt/vestacp/{vesta,home,backup}

docker run -d --restart=always -p 4321:5432 -p 8083:8083 -v /opt/vestacp/vesta:/vesta -v /opt/vestacp/home:/home -v /opt/vestacp/backup:/backup niiknow/vestacp

1. Change admin password.
2. Modify my-startup.sh and comment out mysql start.
3. Connect securely to your PGSQL to any port as in example above mapping to 4321 on docker host.  Welcome to 2017!!!  Your backup is automatically done through VestaCP.
4. Setup cron job to sync /backup folder with aws s3 for remote backup and you're good to go.

## todo/done
- [x] redirected customizable config folders to /vesta, exclude /home.  The folder home has been setup to be it's own volume.  Do not try to redirect the home folder.  It's like opening a big can of worms.  There are all kind of breaking issues with having home as a symbolic link: Vesta FileManager breaking, apache and nginx breaking, SSL breaking, and so on...
- [x] Unfortunately, this is a similar issue with /etc/{passwd,shadow,gshadow,group}; thus, user password persistence is currently implemented as an hourly cronjob.
- [x] AWS CLI has been installed to simplify your backup lifestyle.  You just need to setup a cron on VestaCP.
- [x] Update *index.html* to remove reference to VestaCP from default site for security.
- [x] Dovecot, phpmyadmin, phppgadmin, email, and DNS services are disabled by default.  You can enable them by updating /home/admin/bin/my-startup.sh

If you enabled additional services, you may also want to enable fail2ban.  This will also required that you run docker in with "--privileged" flag.

I'm still working/testing updating internal fail2ban to not do anything and provide instruction on how to read the /vesta/var/log/fail2ban.log file to globally ban the IP from all services.

### misc/tested/verified
- [x] ssh/sftp, nginx, apache2, php7.0 + v8js
- [x] log viewing in Vesta
- [x] backup and restore
- [x] Vesta FileManager
- [x] Letsencrypt
- [x] Sending/outgoing email, dovecot
- [x] phpmyadmin, phppgadmin
- [x] Redis, Memcached
- [x] nodejs, golang
- [x] MariaDB/MySQL, Postgresql, Mongodb
- [x] Fix postgresql backup and restore issue ref - https://github.com/serghey-rodin/vesta/issues/913
- [ ] add incron to monitor and immediately backup /etc/{passwd,shadow,gshadow,group}
- [ ] java, dotnet
- [ ] openvpn

### known issues

### your todo
- [ ] I recommend the following:

1. Since this is Docker, you can run as many services as you want but only expose request port.
2. Change the default/initial *admin* password for security purpose.
3. Instead of using the *admin* acccount, consider creating a different/separate credentials for different website/service.  This will make it easier for backup and recovery; especially, when you need to move the user to a different installation.

### extra
If you use this Docker for hosting and allow your user to login, I also recommend installing maldetect on the docker host to scan the /home volume.

Enjoy!!!

## Upgrading
As this is a docker image, you have many options.

1. The best option is to use VestaCP backup and restore.  
2. I will try to work on migration script to support different version of this docker image, but I would still strongly recommend that you use VestaCP backup and restore.

Let say you followed the instruction above to start your vestacp, the manual upgrade step would be:
*  Make sure you ran your backup and have the latest backup files under /opt/vestacp/backup
*  docker pull niiknow/vestacp:latest
*  docker stop the niiknow/vestacp image
*  tar -czf /opt/vestacp/vesta /opt/vestacp/backup/vesta."$(date +%F_%R)".tar.gz
*  rm -rf /opt/vestacp/vesta/*
*  docker start the new image as instructed above
*  docker rm the old image if everything tested fine or start the old image back if test failed
*  ssh into vesta and restore your users from backup


# LICENSE

The MIT License (MIT)

Copyright (c) 2017 friends@niiknow.org

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.