#!/bin/bash

echo "Setting up keystone"
export SERVICE=keystone
. $SCRIPTS_DIR/common.sh

conf=/etc/keystone/keystone.conf
paste=/etc/keystone/keystone-paste.ini

set -e

conf_setup() {
  echo "...configuration"

  $SCRIPTS_DIR/create-db-and-user.sh keystone keystone $KEYSTONE_DBPASS

  crudini --set $conf DEFAULT admin_token $ADMIN_TOKEN
  crudini --set $conf DEFAULT Verbose True
  crudini --set $conf database connection mysql://keystone:$KEYSTONE_DBPASS@controller/keystone
  crudini --set $conf memcache servers localhost:11211
  crudini --set $conf token provider keystone.token.providers.uuid.Provider
  crudini --set $conf token driver keystone.token.persistence.backends.memcache.Token
  crudini --set $conf revoke driver keystone.contrib.revoke.backends.sql.Revoke
}

db_setup() {
  echo "...database"
  su -s /bin/sh -c "keystone-manage db_sync" keystone

  service keystone restart

  rm -f /var/lib/keystone/keystone.db
}

web_setup() {
  install $TEMPL_DIR/wsgi-keystone.conf /etc/apache2/sites-available/wsgi-keystone.conf
  a2ensite wsgi-keystone
  mkdir -p /var/www/cgi-bin/keystone
  rm -rf /var/www/cgi-bin/keystone/*
  curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo \
    | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin

  chown -R keystone:keystone /var/www/cgi-bin/keystone
  chmod 755 /var/www/cgi-bin/keystone/*

  initctl stop keystone
  service apache2 restart
}


os_setup() {
  echo "...OpenStack services and endpoints"
  service=identity
  user=admin
  role=admin

  os_cmd service create \
      --name keystone --description "OpenStack Identity" $service

  os_cmd endpoint create \
      --publicurl http://controller:5000/v2.0 \
      --internalurl http://controller:5000/v2.0 \
      --adminurl http://controller:35357/v2.0 \
      --region $OS_REGION_NAME \
      $service

  os_cmd user create \
      --password $ADMIN_PASS $user

  os_cmd role create \
      $role

  os_cmd project create \
    admin

  os_cmd role add \
    --project admin --user $user $role

  os_cmd project create --description "Service Project" service
  os_cmd project create --description "Demo Project" demo
  os_cmd user create --password $DEMO_PASS demo
  os_cmd role create user
  os_cmd role add --project demo --user demo user

}

conf_setup
db_setup
web_setup
os_setup
