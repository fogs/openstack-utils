#!/bin/bash

service_name=glance
project=service
user=glance
role=admin
service=image
project_domain_id=default
user_domain_id=default
service_pass="$GLANCE_PASS"
db_pass="$GLANCE_DBPASS"
desc="OpenStack Image service"
pkgs="glance python-glanceclient"
init_services="glance-registry glance-api"

. $SCRIPTS_DIR/setup-include.sh

conf_api=/etc/glance/glance-api.conf
conf_registry=/etc/glance/glance-registry.conf

set -e

conf_setup() {
  echo "...configuration"

  crudini --set $conf_api DEFAULT Verbose True
  crudini --set $conf_api DEFAULT notification_driver noop

  crudini --set $conf_api database connection mysql://${user}:${db_pass}@controller/${service_name}
  crudini --set $conf_api keystone_authtoken auth_url http://controller:35357
  crudini --set $conf_api keystone_authtoken auth_plugin password
  crudini --set $conf_api keystone_authtoken project_domain_id $project_domain_id
  crudini --set $conf_api keystone_authtoken user_domain_id $user_domain_id
  crudini --set $conf_api keystone_authtoken project_name $project
  crudini --set $conf_api keystone_authtoken username $user
  crudini --set $conf_api keystone_authtoken password "$service_pass"

  crudini --set $conf_api paste_deploy flavor keystone

  crudini --set $conf_api glance_store default_store file
  crudini --set $conf_api glance_store filesystem_store_datadir /var/lib/glance/images/

  crudini --set $conf_registry DEFAULT notification_driver noop
  crudini --set $conf_registry DEFAULT Verbose True

  crudini --set $conf_registry database connection mysql://${user}:${db_pass}@controller/${service_name}
  crudini --set $conf_registry keystone_authtoken auth_url http://controller:35357
  crudini --set $conf_registry keystone_authtoken auth_plugin password
  crudini --set $conf_registry keystone_authtoken project_domain_id $project_domain_id
  crudini --set $conf_registry keystone_authtoken user_domain_id $user_domain_id
  crudini --set $conf_registry keystone_authtoken project_name $project
  crudini --set $conf_registry keystone_authtoken username $user
  crudini --set $conf_registry keystone_authtoken password "$service_pass"

  crudini --set $conf_registry paste_deploy flavor keystone

}

db_setup() {
  echo "...database"

  $SCRIPTS_DIR/create-db-and-user.sh $service_name $user "$db_pass"

  su -s /bin/sh -c "${service_name}-manage db_sync" $service_name

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
    --publicurl http://controller:9292 \
    --internalurl http://controller:9292 \
    --adminurl http://controller:9292 \
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

#os_setup
#pkg_setup
conf_setup
db_setup
web_setup
restart_services
