#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Usage: $0 database user password"
  exit 1
fi

db=$1
user=$2
pw=$3

echo "Setting up $user access to $db"

echo "
CREATE DATABASE IF NOT EXISTS $db;
GRANT ALL PRIVILEGES ON $db.* TO '$user'@'localhost' \
  IDENTIFIED BY '$pw';
GRANT ALL PRIVILEGES ON $db.* TO '$user'@'%' \
  IDENTIFIED BY '$pw';
" | mysql -u root -p$MYSQL_PASS
