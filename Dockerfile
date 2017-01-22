FROM niiknow/docker-hostingbase:0.4.8

MAINTAINER friends@niiknow.org

ENV DEBIAN_FRONTEND=noninteractive \
    VESTA=/usr/local/vesta

ADD ./files /
RUN bash /tmp/install/index.sh

VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 6379 8083 10022 11211 27017
