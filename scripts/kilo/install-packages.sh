#!/bin/bash

set -e

apt-get install ubuntu-cloud-keyring

# Remove any (other release) existing sources
rm -f /etc/apt/sources.list.d/cloudarchive-*.list
# Add this release's source
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/$RELEASE main" > /etc/apt/sources.list.d/cloudarchive-$RELEASE.list

apt-get update

packages="
crudini
curl
openvswitch-switch
mariadb-server python-mysqldb
rabbitmq-server
"

DEBIAN_FRONTEND=noninteractive apt-get -y install $packages
