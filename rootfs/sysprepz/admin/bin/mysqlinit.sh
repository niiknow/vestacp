#!/bin/bash
#
#
chmod 777 /var/run/mysqld/mysqld.sock

echo "[mysqld]" > /etc/mysql/conf.d/down.cnf
echo "skip-grant-tables" >> /etc/mysql/conf.d/down.cnf

MYSQL_ROOT_PASSWORD=$1

/etc/init.d/mysql restart

# initialize users
mysql -uroot -e \
  "use mysql; \
  DELETE FROM mysql.user WHERE User='root' ; \
  FLUSH PRIVILEGES ; \
  CREATE USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;\
  GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;\
  FLUSH PRIVILEGES ;\
  "

rm -f /etc/mysql/conf.d/down.cnf

/etc/init.d/mysql restart

exit 0