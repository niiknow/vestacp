fastcgi_cache_path %home%/%user%/web/%domain%/tmp/cache/ levels=1:2 keys_zone=fpm_%domain%:10m max_size=5g inactive=45m use_temp_path=off;

server {
    listen      %proxy_port%;
    server_name %domain_idn% %alias_idn%;
    
    index       index.php index.html index.htm;
    access_log  /var/log/%web_system%/domains/%domain%.log combined;
    access_log  /var/log/%web_system%/domains/%domain%.bytes bytes;
    error_log   /var/log/%web_system%/domains/%domain%.error.log error;

    set $site "%docroot%/public";
    if (!-d %docroot%/public) {
        set $site "%docroot%";
    }
    root        $site;

    location / {
        # allow for custom handling or forcing ssl if necessary
        include %docroot%/sngin*.conf;

        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        try_files $uri /index.php =404;

        # only cache GET request
        if ($request_method != GET) {
            set $no_cache 1;
        }

        # don't cache uris containing the following segments
        if ($request_uri ~* "api/|site/|admin/|dashboard/|cms/|/wp-admin/|wp-.*.php|sitemap.?.xml|xmlrpc.php|/feed/") {
            set $no_cache 1;
        }

        # don't cache with these cookies
        if ($http_cookie ~ (comment_author_.*|wordpress_logged_in.*|wp-postpass_.*)) {
            set $no_cache 1;
        }

        # include default fastcgi_params
        include fastcgi_params;

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/vesta-php-fpm-%domain_idn%.sock;
        fastcgi_index index.php;

        # override default fastcgi_params
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        fastcgi_intercept_errors on;

        fastcgi_cache_use_stale error timeout invalid_header http_500;
        fastcgi_cache_key $host$request_uri;
        fastcgi_cache fpm_%domain%;

        # small amount of cache goes a long way
        fastcgi_cache_valid 200 1m;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
    }

    error_page  403 /error/404.html;
    error_page  404 /error/404.html;
    error_page  500 502 503 504 /error/50x.html;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }
    
    include /etc/nginx/location_optmz_php.conf;

    disable_symlinks if_not_owner from=%home%/%user%/web/%domain%;

    include %home%/%user%/web/%domain%/private/*.conf;
    include %home%/%user%/conf/web/nginx.%domain%.conf*;
}
