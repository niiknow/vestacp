# php-pfm templates
There are two parts to the php-fpm templates: fpm config and nginx.  On the nginx side, you have two options: `php-fpm` or `custom`

![](https://raw.githubusercontent.com/niiknow/vestacp/master/docs/images/php-fpm.png?raw=true)

## nginx
`php-fpm` template is optimize for majority of framework including concrete5, laravel, and/or worpdress.  Outside of that, you have use the `custom` template.  See some examples below.

- - -
`custom` template with [ActiveCollab](https://activecollab.com/)
1. Choose `custom` as your nginx template and php7xfpm template for APACHE2, don't worry, it's not really Apache2, it's really is fpm config just using the same UI as APACHE2.
2. Add a file: /home/{user}/web/{website.example.com}/private/custom.conf

```
    index       proxy.php;
    access_log  /var/log/apache2/domains/{website.example.com}.log combined;
    access_log  /var/log/apache2/domains/{website.example.com}.bytes bytes;

    root "/home/{user}/web/{website.example.com}/public_html/public";

    if (!-e $request_filename) {
        rewrite ^/assets/(.*)$ /assets/$1 last;
        rewrite ^/avatars/(.*)$ /avatars/$1 last;
        rewrite ^/wallpapers/(.*)$ /wallpapers/$1 last;
        rewrite ^/verify-existence$ /verify.php last;
        rewrite ^/proxy.php$ /proxy.php last;
        rewrite ^/api/v([0-9]*)/(.*)$ /api.php?path_info=$2&api_version=$1 last;
        rewrite ^$ /router.php last;
        rewrite ^(.*) /router.php?path_info=$1 last;
    }

    location ~* \.(ico|css|js|gif|jpe?g|png)(\?[0-9]+)?$ {
        expires max;
        log_not_found off;
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
        if (!-e $request_filename) {
            rewrite ^(.*) /router.php?path_info=$1 last;
        }
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

Remember to replace {user} and {website.example.com} with approprivate value.

- - -
**Note**: `custom` template can be use with anything, not just for PHP.

`custom` template for [Gogs](https://gogs.io/)
1. Choose `custom` as your nginx template and `default` for APACHE2.
2. Add a file: /home/{user}/web/{website.example.com}/private/custom.conf
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

- - -

