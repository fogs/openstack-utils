#!/bin/bash

#ASSUMPTIONS
# Machine supports KVM extension of QEMU

service=compute
service_name=nova
# public_url=http://controller:8774/v2/%\(tenant_id\)s
# internal_url=http://controller:8774/v2/%\(tenant_id\)s
# admin_url=http://controller:8774/v2/%\(tenant_id\)s

user=nova
service_pass="$NOVA_PASS"
# db_pass="$NOVA_DBPASS"
# desc="OpenStack Compute"
pkgs="nova-compute sysfsutils"
init_services="nova-compute"
# db_sync_op="db sync"

project=service
role=admin
project_domain_id=default
user_domain_id=default

. $SCRIPTS_DIR/setup-include.sh

conf=/etc/nova/nova.conf

set -e

conf_setup() {
  echo "...configuration"

  crudini --set $conf DEFAULT Verbose True
  crudini --set $conf DEFAULT auth_strategy keystone
  crudini --set $conf DEFAULT rpc_backend rabbit
  crudini --set $conf DEFAULT my_ip $MAIN_ADDR
  crudini --set $conf DEFAULT vnc_enabled True
  crudini --set $conf DEFAULT vncserver_listen $MAIN_ADDR
  crudini --set $conf DEFAULT vncserver_proxyclient_address $MAIN_ADDR
  crudini --set $conf DEFAULT novncproxy_base_url http://$NOVA_ADDR:6080/vnc_auto.html

  crudini --set $conf oslo_messaging_rabbit rabbit_host controller
  crudini --set $conf oslo_messaging_rabbit rabbit_userid openstack
  crudini --set $conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS

  crudini --set $conf keystone_authtoken auth_uri http://controller:5000
  crudini --set $conf keystone_authtoken auth_url http://controller:35357
  crudini --set $conf keystone_authtoken auth_plugin password
  crudini --set $conf keystone_authtoken project_domain_id $project_domain_id
  crudini --set $conf keystone_authtoken user_domain_id $user_domain_id
  crudini --set $conf keystone_authtoken project_name $project
  crudini --set $conf keystone_authtoken username $user
  crudini --set $conf keystone_authtoken password "$service_pass"

  crudini --set $conf glance host $GLANCE_ADDR

  crudini --set $conf oslo_concurrency lock_path /var/lib/nova/tmp

}

db_setup() {
  true
}

web_setup() {
  true
}

os_setup() {
  true
}

pkg_setup() {
  apt-get install -y $pkgs
}

restart_services() {
  for s in $init_services; do
    service $s restart
  done
}

os_setup
pkg_setup
conf_setup
db_setup
web_setup
restart_services
