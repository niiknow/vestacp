server {
    listen      %proxy_port%;
    server_name %domain_idn% %alias_idn%;
    error_log   /var/log/%web_system%/domains/%domain%.error.log error;

    include %home%/%user%/web/%domain%/private/*.conf;
    include %home%/%user%/conf/web/nginx.%domain%.conf*;
}
