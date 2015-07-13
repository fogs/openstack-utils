#!/bin/bash

service=network
service_name=neutron
public_url=http://controller:9696
internal_url=http://controller:9696
admin_url=http://controller:9696

user=neutron
service_pass="$NEUTRON_PASS"
db_pass="$NEUTRON_DBPASS"
desc="OpenStack Networking Compute Node"
pkgs="neutron-plugin-ml2 neutron-plugin-openvswitch-agent"
init_services="nova-compute neutron-plugin-openvswitch-agent"

project=service
role=admin
project_domain_id=default
user_domain_id=default

. $SCRIPTS_DIR/setup-include.sh

conf=/etc/neutron/neutron.conf
conf_sysctl=/etc/sysctl.conf
conf_ml2=/etc/neutron/plugins/ml2/ml2_conf.ini
conf_nova=/etc/nova/nova.conf

set -e

conf_setup() {
  echo "...configuration"

  install $TEMPL_DIR/neutron_compute_sysctl.conf /etc/sysctl.d/99-neutron-compute.conf
  sysctl -p

  crudini --set $conf DEFAULT rpc_backend rabbit
  crudini --set $conf oslo_messaging_rabbit rabbit_host controller
  crudini --set $conf oslo_messaging_rabbit rabbit_userid openstack
  crudini --set $conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS

  crudini --set $conf DEFAULT auth_strategy keystone
  crudini --set $conf keystone_authtoken auth_uri http://controller:5000
  crudini --set $conf keystone_authtoken auth_url http://controller:35357
  crudini --set $conf keystone_authtoken auth_plugin password
  crudini --set $conf keystone_authtoken project_domain_id $project_domain_id
  crudini --set $conf keystone_authtoken user_domain_id $user_domain_id
  crudini --set $conf keystone_authtoken project_name $project
  crudini --set $conf keystone_authtoken username $user
  crudini --set $conf keystone_authtoken password "$service_pass"

  crudini --set $conf DEFAULT core_plugin ml2
  crudini --set $conf DEFAULT service_plugins router
  crudini --set $conf DEFAULT allow_overlapping_ips True

  crudini --set $conf_ml2 ml2 type_drivers flat,vlan,gre,vxlan
  crudini --set $conf_ml2 ml2 tenant_network_types gre
  crudini --set $conf_ml2 ml2 mechanism_drivers openvswitch

  crudini --set $conf_ml2 ml2_type_flat flat_networks external

  crudini --set $conf_ml2 ml2_type_gre tunnel_id_ranges 1:1000

  crudini --set $conf_ml2 securitygroup enable_security_group True
  crudini --set $conf_ml2 securitygroup enable_ipset True
  crudini --set $conf_ml2 securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

  crudini --set $conf_ml2 ovs local_ip $MAIN_ADDR
  crudini --set $conf_ml2 ovs bridge_mappings external:br-ex

  crudini --set $conf_ml2 agent tunnel_types gre


  # ...and the compute side itself
  crudini --set $conf_nova DEFAULT network_api_class nova.network.neutronv2.api.API
  crudini --set $conf_nova DEFAULT security_group_api neutron
  crudini --set $conf_nova DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
  crudini --set $conf_nova DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

  crudini --set $conf_nova neutron http://$NEUTRON_ADDR:9696
  crudini --set $conf_nova neutron auth_strategy keystone
  crudini --set $conf_nova neutron admin_auth_url http://controller:35357/v2.0
  crudini --set $conf_nova neutron admin_tenant_name $project
  crudini --set $conf_nova neutron admin_username $user
  crudini --set $conf_nova neutron admin_password "$service_pass"

}

extra_setup() {
  true
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
extra_setup
