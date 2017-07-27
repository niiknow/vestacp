# sometime you just want full control and this template gives you that
# just add your custom conf file inside of %home%/%user%/web/%domain%/private folder
#
#

## example of how I proxy to my gogs internal service:
# location / {
#  proxy_pass      http://127.0.0.1:10080;
# }

# location /error/ {
#  alias   /home/git/web/git.yourdomain.com/document_errors/;
# }

# location @fallback {
#  proxy_pass      http://127.0.0.1:10080;
# }

# location ~ /\.ht    {return 404;}
# location ~ /\.svn/  {return 404;}
# location ~ /\.git/  {return 404;}
# location ~ /\.hg/   {return 404;}
# location ~ /\.bzr/  {return 404;}

# if ($scheme = http) {
#  return 301 https://$server_name$request_uri;
# }


server {
    listen      %proxy_port%;
    server_name %domain_idn% %alias_idn%;
    error_log   /var/log/%web_system%/domains/%domain%.error.log error;

    include %home%/%user%/web/%domain%/private/*.conf;
    include %home%/%user%/conf/web/nginx.%domain%.conf*;
}

