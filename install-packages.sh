#!/bin/bash

set -e

apt-get update

packages="
openvswitch-switch
mysql-server
rabbitmq-server
"

DEBIAN_FRONTEND=noninteractive apt-get -y install $packages
