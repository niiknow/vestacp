# php-pfm templates
There are two parts to the php-fpm templates: fpm config and nginx.  On the nginx side, you have two options: php-fpm or custom.

## nginx
`php-fpm` template is optimize for majority of framework including concrete5, laravel, and/or worpdress.  Outside of that, you have use the `custom` template.  See some examples below.

Custom template with [ActiveCollab](https://activecollab.com/)
1. Choose `custom` as your nginx template
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

    location /vstats/ {
        alias   /home/{user}/web/{website.example.com}/stats/;
        include /home/{user}/web/{website.example.com}/stats/auth.conf*;
    }

    include /etc/nginx/location_optmz_php.conf;

    disable_symlinks if_not_owner from=/home/{user}/web/{website.example.com};

```

Remember to replace {user} and {website.example.com} with approprivate value.
