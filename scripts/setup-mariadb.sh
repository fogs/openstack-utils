#!/bin/bash

set -e

echo "
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
" | mysql

mysqladmin -u root password $MYSQL_PASS

service mysql restart
