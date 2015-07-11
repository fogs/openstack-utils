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
  crudini --set $conf token provider keystone.token.providers.uuid.Provider
  crudini --set $conf token driver keystone.token.persistence.backends.sql.Token
  crudini --set $conf revoke driver keystone.contrib.revoke.backends.sql.Revoke
}

db_setup() {
  echo "...database"
  su -s /bin/sh -c "keystone-manage db_sync" keystone

  service keystone restart

  rm -f /var/lib/keystone/keystone.db

  (crontab -l -u keystone 2>&1 | grep -q token_flush) || \
  echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' \
  >> /var/spool/cron/crontabs/keystone
}

os_setup() {
  echo "...OpenStack services and endpoints"
  service=identity
  user=admin
  role=admin

  keystone tenant-create --name admin --description "Admin Tenant"
  keystone user-create --name admin --pass $ADMIN_PASS --email root@localhost
  keystone role-create --name admin
  keystone user-role-add --user admin --tenant admin --role admin

  keystone tenant-create --name demo --description "Demo Tenant"
  keystone user-create --name demo --tenant demo --pass $DEMO_PASS --email root@localhost

  keystone tenant-create --name service --description "Service Tenant"

  keystone service-create --name keystone --type identity \
    --description "OpenStack Identity"

  keystone endpoint-create \
    --service-id $(keystone service-list | awk '/ identity / {print $2}') \
    --publicurl http://controller:5000/v2.0 \
    --internalurl http://controller:5000/v2.0 \
    --adminurl http://controller:35357/v2.0 \
    --region $OS_REGION_NAME

  # os_cmd service create \
  #     --name keystone --description "OpenStack Identity" $service
  #
  # os_cmd endpoint create \
  #     --publicurl http://controller:5000/v2.0 \
  #     --internalurl http://controller:5000/v2.0 \
  #     --adminurl http://controller:35357/v2.0 \
  #     --region $OS_REGION_NAME \
  #     $service
  #
  # os_cmd user create \
  #     --password $ADMIN_PASS $user
  #
  # os_cmd role create \
  #     $role
  #
  # os_cmd project create \
  #   admin
  #
  # os_cmd role add \
  #   --project admin --user $user $role
  #
  # os_cmd project create --description "Service Project" service
  # os_cmd project create --description "Demo Project" demo
  # os_cmd user create --password $DEMO_PASS demo
  # os_cmd role create user
  # os_cmd role add --project demo --user demo user

}

conf_setup
db_setup
os_setup
