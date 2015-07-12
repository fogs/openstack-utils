#!/bin/bash

export BASE_DIR=$(cd $(dirname $0); pwd)
export SCRIPTS_DIR=$BASE_DIR/scripts
export TEMPL_DIR=$BASE_DIR/templates
us=${BASE_DIR}/$(basename $0)
export INSTALL_DIR=$HOME/.openstack
export MAIN_ADDR=$($SCRIPTS_DIR/extract-main-address.sh)

#### MAIN #####################################################################

if [ $(id -u) = 0 ]; then
  fatal "This installer cannot be started as root.
We'll prompt you when it's time to sudo to do stuff.
" >&2
fi

mkdir -p $INSTALL_DIR

cd $INSTALL_DIR

$SCRIPTS_DIR/init-passwords.sh install-openrc.sh

. install-openrc.sh
export RELEASE=kilo
export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://controller:35357/v2.0
export OS_REGION_NAME=regionOne

tail -n+$(awk '/^#### START-ROOT/{print NR+1}' $us) $us > /tmp/$$.sh

trap "rm /tmp/$$.sh" EXIT

$SCRIPTS_DIR/setup-openrc.sh

sudo -E bash /tmp/$$.sh

exit

#### START-ROOT ###############################################################
#!/bin/bash

fatal() {
  echo "FATAL ERROR:" $* >&2
  exit 2
}

echo "Continuing installation as $(id -un)..."
#$SCRIPTS_DIR/setup-etc-hosts.sh 127.0.0.1 || fatal "Setting up /etc/hosts"
#$SCRIPTS_DIR/install-packages.sh || fatal "Installing packages"
#$SCRIPTS_DIR/setup-mariadb.sh || fatal "Setting up MariaDB"
#$SCRIPTS_DIR/setup-rabbitmq.sh || fatal "Setting up RabbitMQ"

#$SCRIPTS_DIR/setup-keystone.sh || fatal "Setting up Keystone"
. admin-openrc.sh

#$SCRIPTS_DIR/setup-glance.sh || fatal "Setting up Glance"
$SCRIPTS_DIR/setup-horizon.sh || fatal "Setting up Horizon"
