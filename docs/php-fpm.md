# php-pfm templates
There are two config to the php-fpm templates: fpm and nginx.  On the nginx side, you have two options: `php-fpm` or `custom`

![](https://raw.githubusercontent.com/niiknow/vestacp/master/docs/images/php-fpm.png?raw=true)

## nginx
`php-fpm` template is optimize for majority of framework including concrete5, laravel, and/or wordpress.  Outside of that, you have use the `custom` template.  See some examples below.

- - -
`custom` template with [ActiveCollab](https://activecollab.com/)
1. Choose `custom` as your nginx template and php7xfpm template for APACHE2.  Don't worry, it's not really Apache2.  It's is fpm config just re-using the same UI as APACHE2.
2. Add a file: `/home/{user}/web/{website.example.com}/private/custom.conf`

```
    index       proxy.php;
    access_log  /var/log/apache2/domains/{website.example.com}.log combined;
    access_log  /var/log/apache2/domains/{website.example.com}.bytes bytes;

    root "/home/{user}/web/{website.example.com}/public_html/public";

    set $can_rewrite 0;

    if (!-e $request_filename) {
        set $can_rewrite 1;
    }

    if ($uri ~ ".well-known") {
        set $can_rewrite 0;
    }

    if ($can_rewrite = 1) {
        rewrite ^/assets/(.*)$ /assets/$1 last;
        rewrite ^/avatars/(.*)$ /avatars/$1 last;
        rewrite ^/wallpapers/(.*)$ /wallpapers/$1 last;
        rewrite ^/verify-existence$ /verify.php last;
        rewrite ^/proxy.php$ /proxy.php last;
        rewrite ^/api/v([0-9]*)/(.*)$ /api.php?path_info=$2&api_version=$1 last;
        rewrite ^$ /router.php last;
        rewrite ^(.*) /router.php?path_info=$1 last;
    }

    location / {
        rewrite ^/verify-existence$ /verify.php last;
        rewrite ^/proxy.php$ /proxy.php last;
        rewrite ^/api/v([0-9]*)/(.*)$ /api.php?path_info=$2&api_version=$1 last;
        rewrite ^/$ /router.php last;

        try_files $uri $uri/ /router.php?path_info=$uri&$args;
    }

    location ~ \.php$ {
        # force https-redirects if not http
        if ($scheme = http) {
           return 301 https://$server_name$request_uri;
        }

        fastcgi_pass unix:/var/run/vesta-php-fpm-{website.example.com}.sock;
        include /etc/nginx/fastcgi_params;

        # overriding default
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        fastcgi_intercept_errors on;
    }

    error_page  403 /error/404.html;
    error_page  404 /error/404.html;
    error_page  500 502 503 504 /error/50x.html;

    location /error/ {
        alias   /home/{user}/web/{website.example.com}/document_errors/;
    }

    include /etc/nginx/location_optmz_php.conf;

    disable_symlinks if_not_owner from=/home/{user}/web/{website.example.com};

```

Remember to replace `{user}` and `{website.example.com}` with appropriate/valid value.

- - -
**Note**: `custom` template can be use with anything, not just for PHP.

`custom` template for [Gogs](https://gogs.io/) (self-hosted git written in Golang) or any kind of service that you want to nginx proxy_pass such as service running with nodejs, dotnet, etc...

1. Choose `custom` as your nginx template and `default` for APACHE2.
2. Add a file: `/home/{user}/web/{website.example.com}/private/custom.conf`

```
location / {
   # force https-redirects if not http
   if ($scheme = http) {
      return 301 https://$server_name$request_uri;
   }

   proxy_pass      http://127.0.0.1:10080;
}

location /error/ {
   alias   /home/{user}/web/{website.example.com}/document_errors/;
}

location @fallback {
   proxy_pass      http://127.0.0.1:10080;
}

include /etc/nginx/location_optmz_php.conf;
```

This assume that you're running Gogs Web on port 10080 so we proxy that port.  Your gogs `app.ini` may look like so:

```
$ cat app.ini
APP_NAME = Your Git Service
RUN_USER = {user}
RUN_MODE = prod

[database]
DB_TYPE  = sqlite3
HOST     = none
NAME     = none
USER     = none
PASSWD   = 
SSL_MODE = disable
PATH     = /home/{user}/gogs/data/gogs.db

[repository]
ROOT = /home/{user}/gogs-repos

[server]
DOMAIN           = git.example.com
HTTP_PORT        = 10080
ROOT_URL         = https://git.example.com/
DISABLE_SSH      = false
START_SSH_SERVER = true
SSH_DOMAIN       = %(DOMAIN)s
SSH_LISTEN_HOST  = 0.0.0.0
SSH_PORT         = 22
SSH_LISTEN_PORT  = 10022
OFFLINE_MODE     = false
CERT_FILE        = custom/https/cert.pem
KEY_FILE         = custom/https/key.pem
ENABLE_GZIP      = true
LANDING_PAGE     = home

[mailer]
ENABLED          = true
HELO_HOSTNAME    = git.example.com
HOST             = smtp.gmail.com:587
USER             = git@example.com
PASSWD           = your-email-password

[service]
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL     = true
DISABLE_REGISTRATION   = false
ENABLE_CAPTCHA         = true
REQUIRE_SIGNIN_VIEW    = true

[picture]
DISABLE_GRAVATAR        = false
ENABLE_FEDERATED_AVATAR = false

[session]
PROVIDER = file

[log]
MODE      = file
LEVEL     = Info
ROOT_PATH = /home/{user}/gogs/log

[security]
INSTALL_LOCK = true
SECRET_KEY   = 32AdfjlkksjdfA
```

- - -
`phpfcgi7x` with `default` nginx template - use this if you need to work with .htaccess file.  Let say you unzip Laravel into the `/home/{user}/web/{website.example.com}/lara-app` folder, then you want to create a symbolic link to `public_html` folder like so:
```
ln -s lara-app/public public_html
```

- - -

