location ~ ^/(phpmyadmin|phppgadmin) {
    # replacing phpmyadmin and phppgadmin
    rewrite ^ /dbadmin last;
}

location ~ ^/dbadmin {
    alias /usr/share/adminer/public/;
    index index.php;

    # allow for additional adminer config
    include /etc/nginx/conf.d/adminer*.inc;

    location ~ ^/dbadmin/(.*\.php)$ {
        try_files $uri /index.php =404;

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass  unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
