#!/bin/bash

out=${1:-openstackrc}

if [ -f $out ]; then
  echo "$out already exists, so no need to re-create" >&2
  exit 1
fi

function random_password()
{
  apg -n 1 -m 24 -a 1 -M NCL
}

cat > $out <<EOF
export MYSQL_PASS=$(random_password)
export RABBIT_PASS=$(random_password)
export KEYSTONE_DBPASS=$(random_password)
export DEMO_PASS=$(random_password)
export ADMIN_TOKEN=$(random_password)
export ADMIN_PASS=$(random_password)
export GLANCE_DBPASS=$(random_password)
export GLANCE_PASS=$(random_password)
export NOVA_DBPASS=$(random_password)
export NOVA_PASS=$(random_password)
export NOVA_METADATA_SECRET=$(random_password)
export DASH_DBPASS=$(random_password)
export CINDER_DBPASS=$(random_password)
export CINDER_PASS=$(random_password)
export NEUTRON_DBPASS=$(random_password)
export NEUTRON_PASS=$(random_password)
export HEAT_DBPASS=$(random_password)
export HEAT_PASS=$(random_password)
export CEILOMETER_DBPASS=$(random_password)
export CEILOMETER_PASS=$(random_password)
export TROVE_DBPASS=$(random_password)
export TROVE_PASS=$(random_password)
EOF

echo "Generated $out"

