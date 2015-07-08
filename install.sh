#!/bin/bash

export BASE_DIR=$(cd $(dirname $0); pwd)
export SCRIPTS_DIR=$BASE_DIR/scripts
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

$SCRIPTS_DIR/init-passwords.sh openstackrc
. openstackrc

tail -n+$(awk '/^#### START-ROOT/{print NR+1}' $us) $us | sudo -E bash

exit

#### START-ROOT ###############################################################
#!/bin/bash

fatal() {
  echo $* >&2
  exit 2
}

echo "Continuing installation as $(id -n)..."
$SCRIPTS_DIR/install-packages.sh || fatal "Installing packages"
