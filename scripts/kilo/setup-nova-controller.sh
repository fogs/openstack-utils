#!/bin/bash

service=compute
service_name=nova
public_url=http://controller:8774/v2/%\(tenant_id\)s
internal_url=http://controller:8774/v2/%\(tenant_id\)s
admin_url=http://controller:8774/v2/%\(tenant_id\)s

user=nova
service_pass="$NOVA_PASS"
db_pass="$NOVA_DBPASS"
desc="OpenStack Compute"
pkgs="nova-api nova-cert nova-conductor nova-consoleauth
  nova-novncproxy nova-scheduler python-novaclient"
init_services="nova-api nova-cert nova-consoleauth nova-scheduler nova-conductor nova-novncproxy"
db_sync_op="db sync"

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
  crudini --set $conf DEFAULT vncserver_listen $MAIN_ADDR
  crudini --set $conf DEFAULT vncserver_proxyclient_address $MAIN_ADDR

  crudini --set $conf database connection mysql://${user}:${db_pass}@controller/${service_name}

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

  crudini --set $conf oslo_concurrency lock_path /var/lib/nova/tmp


  # For Neutron networking
  crudini --set $conf DEFAULT network_api_class nova.network.neutronv2.api.API
  crudini --set $conf DEFAULT security_group_api neutron
  crudini --set $conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
  crudini --set $conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

  crudini --set $conf neutron url http://$NEUTRON_ADDR:9696
  crudini --set $conf neutron auth_strategy keystone
  crudini --set $conf neutron admin_auth_url http://controller:35357/v2.0
  crudini --set $conf neutron admin_tenant_name $project
  crudini --set $conf neutron admin_username neutron
  crudini --set $conf neutron admin_password $NEUTRON_PASS

}

db_setup() {
  echo "...database"

  $SCRIPTS_DIR/create-db-and-user.sh $service_name $user "$db_pass"

  su -s /bin/sh -c "${service_name}-manage $db_sync_op" $service_name

  rm -f /var/lib/${service_name}/${service_name}.db
}

web_setup() {
  true
}


os_setup() {
  echo "...OpenStack services and endpoints"

  os_cmd user create \
      --password $service_pass $user

  os_cmd role add \
    --project $project --user $user $role

  os_cmd service create \
      --name $service_name --description "$desc" $service

  os_cmd endpoint create \
    --publicurl "$public_url" \
    --internalurl "$internal_url" \
    --adminurl "$admin_url" \
    --region $OS_REGION_NAME \
    $service
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
