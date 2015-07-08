#!/bin/bash

set -e

apt-get install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

apt-get update

packages="
openvswitch-switch
mariadb-server python-mysqldb
rabbitmq-server
"

DEBIAN_FRONTEND=noninteractive apt-get -y install $packages
