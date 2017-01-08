# vestacp
VestaCP with docker (thanks lagun4ik for a great start)

Running this image:

docker run -d \
  --restart=always \
  -p 2222:22 \
  -p 25:25 \
  -p 53:53 \
  -p 54:54 \
  -p 80:80 \
  -p 110:110 \
  -p 993:993 \
  -p 443:443 \
  -p 3306:3306 \
  -p 5432:5432 \
  -p 8083:8083 \
  -v vestacp-data:/vesta -v vestacp-data:/home -v vestacp-data:/backup \
  niiknow/vestacp

## Authorization

Login: admin Password: MakeItSo17

## SSH for FTP

Use SFTP instead of FTP on the 2222 port.

## TODO
- [x] All redirectable folders has been redirected to /vesta except for /home.  Do not try to redirect the home folder.  It's like opening a big can of worms.  There are all kind of issues with having home as a symbolic link: Vesta FileManager breaking, apache and nginx breaking, SSL breaking, and even security issues if it has not already been restricted by apache config to not follow symlinks.
- [x] Unfortunately, this is a similar issue with /etc/{passwd,shadow,gshadow,group} and I do not have a good solution.  The current patch is to perform an hourly sync/backup of these files.  We then replace these files on init in my-startup.sh file.  You shouldn't be changing your password or adding new users very often; and if you do, please wait at least an hour for the sync to occurred before doing any maintenance.
- [x] Both AWS CLI and s3cmd has been installed to simplify your backup lifestyle.  You just need to setup a cron on VestaCP.
- [x] Update *index.html* to remove reference to VestaCP from admin default site for security.
- [x] Disable *phpmyadmin* by default for security.  You can re-enable by moving the file back from /vesta/etc-bak/apache/conf.d/phpmyadmin.conf.  This is because phpmyadmin with fastcgi does not log to syslog; therefore, it is susceptible to brute force attacks.  On the other hand *phppgadmin* has been configured with fail2ban.
- [x] Redirect *startup.sh* to /vesta/my-startup.sh so you can control startups

### misc/tested
- [x] nginx, apache, log viewing
- [x] Vesta FileManager
- [x] Letsencrypt
- [x] Send Email 
- [x] fail2ban 
- [x] Backup
- [x] DNS Server and Receive Mail - only if it's necessary, I don't recommend hosting critical service such as DNS and email on docker.

### your todo
- [ ] Since this is a docker Control Panel that you will need to do the following:

1. Only expose port that you required.
2. Change the default/initial *admin* password for security purpose.
3. Instead of using the *admin* acccount, consider creating a different credential.  This make it easier for backup and recovery when you need to move the user to a different installation.

