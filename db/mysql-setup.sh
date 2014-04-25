#!/bin/sh

set -e
set -x

sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# sed -i '/^datadir*/ s|/var/lib/mysql|/data/mysql|' /etc/mysql/my.cnf

# rm -Rf /var/lib/mysql

chown -R mysql.mysql /var/lib/mysql
mysql_install_db --datadir=/var/data --user=mysql

/usr/sbin/mysqld --datadir=/var/data &
sleep 5
echo "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

cat /proxy_board.sql | mysql
