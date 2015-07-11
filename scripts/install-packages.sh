#!/bin/bash

set -e

apt-get install ubuntu-cloud-keyring

# Remove any (other release) existing sources
rm -f /etc/apt/sources.list.d/cloudarchive-*.list
# Add this release's source
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/$RELEASE main" > /etc/apt/sources.list.d/cloudarchive-$RELEASE.list

apt-get update

echo "manual" > /etc/init/keystone.override

packages="
crudini
curl
openvswitch-switch
mariadb-server python-mysqldb
rabbitmq-server
keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache
"

DEBIAN_FRONTEND=noninteractive apt-get -y install $packages
