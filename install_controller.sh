#!/bin/bash

export BASE_DIR=$(cd $(dirname $0); pwd)
export SCRIPTS_DIR=$BASE_DIR/scripts
export TEMPL_DIR=$BASE_DIR/templates
export INSTALL_DIR=$HOME/.openstack
export MAIN_ADDR=$($SCRIPTS_DIR/extract-main-address.sh)
export GLANCE_ADDR=controller
export NOVA_ADDR=controller
export NEUTRON_ADDR=controller
export RELEASE=ocata
export OS_URL=http://controller:35357/v2.0
export OS_REGION_NAME=regionOne

mkdir -p $INSTALL_DIR

fatal() {
  echo "FATAL ERROR:" $* >&2
  exit 2
}

$SCRIPTS_DIR/install-packages.sh || fatal "Installing packages"

$SCRIPTS_DIR/init-passwords.sh $INSTALL_DIR/install-openrc.sh
. $INSTALL_DIR/install-openrc.sh

export OS_TOKEN=$ADMIN_TOKEN

$SCRIPTS_DIR/setup-openrc.sh

$SCRIPTS_DIR/setup-etc-hosts.sh 127.0.0.1 || fatal "Setting up /etc/hosts"
$SCRIPTS_DIR/setup-mariadb.sh || fatal "Setting up MariaDB"
$SCRIPTS_DIR/setup-rabbitmq.sh || fatal "Setting up RabbitMQ"

$SCRIPTS_DIR/setup-keystone.sh || fatal "Setting up Keystone"
. admin-openrc.sh

$SCRIPTS_DIR/setup-glance.sh || fatal "Setting up Glance"
$SCRIPTS_DIR/setup-nova-controller.sh || fatal "Setting up Nova Controller"
$SCRIPTS_DIR/setup-nova-node.sh || fatal "Setting up Nova Node"
$SCRIPTS_DIR/setup-neutron-controller.sh || fatal "Setting up Neutron Controller"
$SCRIPTS_DIR/setup-neutron-node.sh || fatal "Setting up Neutron Node"
$SCRIPTS_DIR/setup-neutron-compute.sh || fatal "Setting up Neutron Compute Node"
$SCRIPTS_DIR/setup-horizon.sh || fatal "Setting up Horizon"
