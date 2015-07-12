#!/bin/bash

service_name=horizon
project=service
user=horizon
role=admin
service=dashboard
project_domain_id=default
user_domain_id=default
desc="OpenStack Dashboard"
pkgs="openstack-dashboard"
init_services="apache2"

. $SCRIPTS_DIR/setup-include.sh

conf=/etc/openstack-dashboard/local_settings.py

set -e

conf_setup() {
  echo "...configuration"

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
  service apache2 reload
}

os_setup
pkg_setup
conf_setup
db_setup
web_setup
restart_services
