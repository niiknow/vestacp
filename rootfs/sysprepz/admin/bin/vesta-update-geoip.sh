#!/bin/sh

# get environment variables
source /etc/container_environment.sh

# update geoip database
# separate script so you can run it in cron if needed
cd /tmp
mkdir -p /etc/nginx/geoip2/
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
tar xaf GeoLite2-Country.tar.gz --strip 1
mv -f GeoLite2-Country.mmdb /etc/nginx/geoip2/

wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
tar xaf GeoLite2-City.tar.gz --strip 1
mv -f GeoLite2-City.mmdb /etc/nginx/geoip2/
