#!/bin/bash

service=network
service_name=neutron
public_url=http://controller:9696
internal_url=http://controller:9696
admin_url=http://controller:9696

user=neutron
service_pass="$NEUTRON_PASS"
db_pass="$NEUTRON_DBPASS"
desc="OpenStack Networking"
pkgs="neutron-server neutron-plugin-ml2 python-neutronclient"
init_services="nova-api neutron-server"
db_sync_op="db sync"

project=service
role=admin
project_domain_id=default
user_domain_id=default

. $SCRIPTS_DIR/setup-include.sh

conf=/etc/neutron/neutron.conf
conf_ml2=/etc/neutron/plugins/ml2/ml2_conf.ini

set -e

conf_setup() {
  echo "...configuration"

  crudini --set $conf DEFAULT Verbose True
  crudini --set $conf DEFAULT auth_strategy keystone
  crudini --set $conf DEFAULT rpc_backend rabbit
  crudini --set $conf DEFAULT core_plugin ml2
  crudini --set $conf DEFAULT service_plugins router
  crudini --set $conf DEFAULT allow_overlapping_ips True
  crudini --set $conf DEFAULT notify_nova_on_port_status_changes True
  crudini --set $conf DEFAULT notify_nova_on_port_data_changes True
  crudini --set $conf DEFAULT nova_url http://$NOVA_ADDR:8774/v2

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

  crudini --set $conf nova auth_url http://controller:35357
  crudini --set $conf nova auth_plugin password
  crudini --set $conf nova project_domain_id $project_domain_id
  crudini --set $conf nova user_domain_id $user_domain_id
  crudini --set $conf nova region_name $OS_REGION_NAME
  crudini --set $conf nova project_name $project
  crudini --set $conf nova username nova
  crudini --set $conf nova password "$NOVA_PASS"

  crudini --set $conf_ml2 ml2 type_drivers flat,vlan,gre,vxlan
  crudini --set $conf_ml2 ml2 tenant_network_types gre
  crudini --set $conf_ml2 ml2 mechanism_drivers openvswitch

  crudini --set $conf_ml2 ml2_type_gre tunnel_id_ranges 1:1000
  crudini --set $conf_ml2 securitygroup enable_security_group True
  crudini --set $conf_ml2 securitygroup enable_ipset True
  crudini --set $conf_ml2 securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

}

db_setup() {
  echo "...database"

  $SCRIPTS_DIR/create-db-and-user.sh $service_name $user "$db_pass"

  su -s /bin/sh -c "neutron-db-manage --config-file $conf --config-file $conf_ml2 upgrade head" $service_name

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

# os_setup
# pkg_setup
conf_setup
# db_setup
# web_setup
restart_services
