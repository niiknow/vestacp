# VestaCP
The ultimate control panel with docker (thanks lagun4ik for a great start)

What's included?
* ubuntu 16.04 lts + Vesta 0.9.8-17
* nginx (proxy) -> apache2 -> php7.0 - high performance and flexible implementation
* ssh/sftp, letsencrypt, memcached, redis, MariaDB 10.1, postgresql 9.5, nodejs 8.x, golang 1.8.3, openvpn, mongodb, couchdb
* folder redirection for data persistence and automatic daily backup provided by VestaCP
* DNS, named, dovecot/roundcube, spamassassin, clamav, fail2ban, etc... -- disabled by default

Run this image:
```
mkdir -p /opt/vestacp/{vesta,home,backup}

docker run -d --restart=always \
-p 2222:22 -p 80:80 -p 443:443 -p 3306:3306 -p 5432:5432 -p 8083:8083 \
-v /opt/vestacp/vesta:/vesta -v /opt/vestacp/home:/home -v /opt/vestacp/backup:/backup \
niiknow/vestacp
```

## Volumes
/vesta  -- configurations

/home   -- users data

/backup -- users backup

## Authorization
Login: admin Password: MakeItSo17

## SSH for FTP
FTP was not installed on purpose because it's not secure.  Use SFTP instead on the 2222 port.  Disable ssh if you don't really need it and use the Vesta FileManager plugin.  Also, make sure you change the user shell in the Vesta panel in order to use ssh.

## todo/done
- [x] redirected customizable config folders to /vesta, exclude /home.  Home has been setup to be it's own volume.  Do not try to redirect the home folder.  It's like opening a big can of worms.  There are all kind of breaking issues with having home as a symbolic link: Vesta FileManager breaking, Apache and Nginx breaking, SSL breaking, and so on...
- [x] Use incrond to watch /etc/{passwd,shadow,gshadow,group} and sync to /backup/.etc so remember to attach the backup volume if you want to save password across restart.
- [x] AWS CLI has been installed to simplify your backup lifestyle.  You just need to setup a cron on VestaCP.
- [x] Update *index.html* to remove reference to VestaCP from default site for security.
- [x] **Dovecot/roundcube email, phpmyadmin, phppgadmin, and DNS services** are disabled by default.  Look at /home/admin/bin/my-startup.sh for instruction on how to re-enable these services.

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
- [x] add incron to monitor and immediately backup /etc/{passwd,shadow,gshadow,group}
- [ ] java, dotnet
- [ ] openvpn
- [ ] nginx pagespeed module

### known issues
- [ ] MariaDB password is not saved across backup and restore.  After you restore, go to VESTA DB admin UI and update the password.

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

https://vestacp.com/docs/#how-to-migrate-user-to-another-server

Let say you followed the instruction above to start your vestacp, the manual upgrade step would be:
*  Make sure you ran your backup and have the latest backup files under /opt/vestacp/backup
*  docker pull niiknow/vestacp:latest
*  docker stop the niiknow/vestacp image
*  tar -czf /opt/vestacp/vesta /opt/vestacp/backup/vesta."$(date +%F_%R)".tar.gz
*  rm -rf /opt/vestacp/vesta/*
*  docker start the new image as instructed above
*  docker rm the old image if everything tested fine or start the old image back if test failed
*  ssh into vesta and restore your users from backup: https://vestacp.com/docs/#how-to-migrate-user-to-another-server

## Release Notes
0.8.xx - add pagespeed and prep for next vesta release.  It has been completely redone in anticipation for next VestaCP release and to include Nginx Pagespeed module so in order to upgrade to this image; please perform user backup, download of backup, and restore. It's the same step as you would expect to migrate another server: https://vestacp.com/docs/#how-to-migrate-user-to-another-server 


0.8.30 - first stable image

# LICENSE

The MIT License (MIT)

Copyright (c) 2017 friends@niiknow.org

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
