# VestaCP
The ultimate control panel with docker (thanks lagun4ik for a great start)

What's included with VestaCP?
* ubuntu 16.04 lts + Vesta 0.9.8-17
* nginx (proxy)->apache2->php7.0 - high performance implementation
* letsencrypt, memcached, redis, mysql 5.7, postgresql 9.5, nodejs 6.x
* folder redirection for configuration persistence and automatic backup provided by VestaCP
* SSH/SFTP, DNS, named, dovecot, spamassassin, clamav, etc... - installed but author does not recommend running inside of docker

Running this image:

docker run -d \
  --restart=always \
  -p 2222:22 \
  -p 80:80 \
  -p 443:443 \
  -p 3306:3306 \
  -p 5432:5432 \
  -p 8083:8083 \
  -v vestacp-data:/vesta -v vestacp-data:/home -v vestacp-data:/backup \
  niiknow/vestacp

## Volumes
/vesta  -- all configurations
/home   -- users data
/backup -- users backup

## Authorization
Login: admin Password: MakeItSo17

## SSH for FTP
Use SFTP instead of FTP on the 2222 port.  Disable ssh if you don't really need it, and use the Vesta FileManager plugin.

## Note
Please redirect mysql and postgresql port for additional security.  Feel free to redirect VestaCP port 8083 to something more private.

## Welcome to Hosting in 2017!
Below are scenarios that work great with this docker.

### Secure, High Performance, and Reliable WordPress Site in 2017
docker run -d \
  --restart=always \
  -p 80:80 \
  -p 443:443 \
  -p 3306:3306 \
  -p 8083:8083 \
  -v vestacp-data:/vesta -v vestacp-data:/home -v vestacp-data:/backup \
  niiknow/vestacp

1. Change admin password
2. Modify my-startup.sh and comment out postgresql start.  Install your wordpress site through VestaCP with FileManager.
3. Setup Letsencrypt to help with security and SEO.  Welcome to 2017!!!
4. Setup cron job to sync /backup folder with aws s3 for remote backup and you're good to go.

### Secure, High Performance, and Reliable MYSQL Server 2017
docker run -d \
  --restart=always \
  -p 4321:3306 \
  -p 8083:8083 \
  -v vestacp-data:/vesta -v vestacp-data:/home -v vestacp-data:/backup \
  niiknow/vestacp

1. Change admin password.
2. Modify my-startup.sh and comment out postgresql start.
3. Connect securely to your MYSQL to any port as in example above mapping to 4321 on docker host.  Welcome to 2017!!!  Your backup is automatically done through VestaCP.
4. Setup cron job to sync /backup folder with aws s3 for remote backup and you're good to go.

### Secure, High Performance, and Reliable Postgresql Server
docker run -d \
  --restart=always \
  -p 4321:5432 \
  -p 8083:8083 \
  -v vestacp-data:/vesta -v vestacp-data:/home -v vestacp-data:/backup \
  niiknow/vestacp

1. Change admin password.
2. Modify my-startup.sh and comment out mysql start.
3. Connect securely to your PGSQL to any port as in example above mapping to 4321 on docker host.  Welcome to 2017!!!  Your backup is automatically done through VestaCP.
4. Setup cron job to sync /backup folder with aws s3 for remote backup and you're good to go.

## TODO
- [x] All redirectable folders has been redirected to /vesta except for /home.  Do not try to redirect the home folder.  It's like opening a big can of worms.  There are all kind of issues with having home as a symbolic link: Vesta FileManager breaking, apache and nginx breaking, SSL breaking, and even security issues if it has not already been restricted by apache config to not follow symlinks.
- [x] Unfortunately, this is a similar issue with /etc/{passwd,shadow,gshadow,group} and I do not have a good solution for persisting your user and password.  It's currently backup these files on an hourly basis and sync on startup with my-startup.sh file.  You shouldn't be changing your password or adding new users very often; and if you do, please wait at least an hour before doing any reboot.
- [x] Both AWS CLI and s3cmd has been installed to simplify your backup lifestyle.  You just need to setup a cron on VestaCP.
- [x] Update *index.html* to remove reference to VestaCP from admin default site for security.
- [x] Redirect *startup.sh* to /vesta/my-startup.sh so you can control/customize your startups.
- [ ] Unfortunately, due to not being able to secure from brute force attack inside of docker with fail2ban + iptables, phpmyadmin and phppgadmin are disabled by default.  I also do not suggest exposing DNS Server and/or Email Server/Receiving/Inbox services.  These services has been disabled but can be re-enabled in my-startup.sh file.  Though, you have been warned of potential issues.

### misc/tested
- [x] nginx, apache, log viewing
- [x] Vesta FileManager
- [x] Letsencrypt
- [x] Sending Email 
- [x] Backup and restore

### your todo
- [ ] Since this is a docker Control Panel that you will need to do the following:

1. Only expose port that you required.
2. Change the default/initial *admin* password for security purpose.
3. Instead of using the *admin* acccount, consider creating a different credential.  This make it easier for backup and recovery when you need to move the user to a different installation.

### extra
I also recommend installing maldetect on the docker host machine for scanning of the /home folder inside the data container.

Enjoy!!!