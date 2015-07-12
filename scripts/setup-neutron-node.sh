#!/bin/bash

service=network
service_name=neutron
public_url=http://controller:9696
internal_url=http://controller:9696
admin_url=http://controller:9696

user=neutron
service_pass="$NEUTRON_PASS"
db_pass="$NEUTRON_DBPASS"
desc="OpenStack Networking Node"
pkgs="neutron-plugin-ml2 neutron-plugin-openvswitch-agent
  neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent"
init_services="neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent
  nova-api openvswitch-switch"

br_ex=br-ex
if_ex=eth0

project=service
role=admin
project_domain_id=default
user_domain_id=default

. $SCRIPTS_DIR/setup-include.sh

conf=/etc/neutron/neutron.conf
conf_sysctl=/etc/sysctl.conf
conf_ml2=/etc/neutron/plugins/ml2/ml2_conf.ini
conf_l3_agent=/etc/neutron/l3_agent.ini
conf_dhcp_agent=/etc/neutron/dhcp_agent.ini
conf_dnsmasq=/etc/neutron/dnsmasq-neutron.conf
conf_metadata_agent=/etc/neutron/metadata_agent.ini
conf_nova=/etc/nova/nova.conf

set -e

conf_setup() {
  echo "...configuration"
set -x
  install $TEMPL_DIR/neutron_sysctl.conf /etc/sysctl.d/99-neutron.conf
  sysctl -p

  crudini --set $conf DEFAULT core_plugin ml2
  crudini --set $conf DEFAULT service_plugins router
  crudini --set $conf DEFAULT allow_overlapping_ips True

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

  crudini --set $conf_l3_agent DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  # NOTE from install docs:
  # The external_network_bridge option intentionally lacks a value to enable multiple external networks on a single agent.
  crudini --set $conf_l3_agent DEFAULT external_network_bridge ''
  crudini --set $conf_l3_agent DEFAULT router_delete_namespaces True
  crudini --set $conf_l3_agent DEFAULT verbose True

  crudini --set $conf_dhcp_agent DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  crudini --set $conf_dhcp_agent DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
  crudini --set $conf_dhcp_agent DEFAULT dhcp_delete_namespaces True
  crudini --set $conf_dhcp_agent DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf
  crudini --set $conf_dhcp_agent DEFAULT verbose True

  touch $conf_dnsmasq
  chown root:$user $conf_dnsmasq
  crudini --set $conf_dnsmasq '' dhcp-option-force "26,1454"
  if ! pkill dnsmasq; then
    true
  fi

  crudini --set $conf_metadata_agent DEFAULT auth_uri http://controller:5000
  crudini --set $conf_metadata_agent DEFAULT auth_url http://controller:35357
  crudini --set $conf_metadata_agent DEFAULT auth_region OS_REGION_NAME
  crudini --set $conf_metadata_agent DEFAULT auth_plugin password
  crudini --set $conf_metadata_agent DEFAULT project_domain_id $project_domain_id
  crudini --set $conf_metadata_agent DEFAULT user_domain_id $user_domain_id
  crudini --set $conf_metadata_agent DEFAULT project_name $project
  crudini --set $conf_metadata_agent DEFAULT username $user
  crudini --set $conf_metadata_agent DEFAULT password "$service_pass"

  crudini --set $conf_metadata_agent DEFAULT nova_metadata_ip $NOVA_ADDR
  crudini --set $conf_metadata_agent DEFAULT metadata_proxy_shared_secret $NOVA_METADATA_SECRET
  crudini --set $conf_metadata_agent DEFAULT verbose True

  crudini --set $conf_nova neutron service_metadata_proxy True
  crudini --set $conf_nova neutron metadata_proxy_shared_secret $NOVA_METADATA_SECRET

}

extra_setup() {

  if ! ovs-vsctl list-br | grep $br_ex > /dev/null; then
    ovs-vsctl add-br $br_ex
    ovs-vsctl add-port $br_ex $if_ex
  fi

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

# os_setup
# pkg_setup
conf_setup
# db_setup
# web_setup
restart_services
# extra_setup
