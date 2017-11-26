#!/bin/bash

out=${1:-openstackrc}

if [ -f $out ]; then
  echo "$out already exists, so no need to re-create" >&2
  exit 1
fi

cat > $out <<EOF
export MYSQL_PASS=$(openssl rand -hex 10)
export RABBIT_PASS=$(openssl rand -hex 10)
export KEYSTONE_DBPASS=$(openssl rand -hex 10)
export DEMO_PASS=$(openssl rand -hex 10)
export ADMIN_TOKEN=$(openssl rand -hex 10)
export ADMIN_PASS=$(openssl rand -hex 10)
export GLANCE_DBPASS=$(openssl rand -hex 10)
export GLANCE_PASS=$(openssl rand -hex 10)
export NOVA_DBPASS=$(openssl rand -hex 10)
export NOVA_PASS=$(openssl rand -hex 10)
export NOVA_METADATA_SECRET=$(openssl rand -hex 10)
export DASH_DBPASS=$(openssl rand -hex 10)
export CINDER_DBPASS=$(openssl rand -hex 10)
export CINDER_PASS=$(openssl rand -hex 10)
export NEUTRON_DBPASS=$(openssl rand -hex 10)
export NEUTRON_PASS=$(openssl rand -hex 10)
export HEAT_DBPASS=$(openssl rand -hex 10)
export HEAT_PASS=$(openssl rand -hex 10)
export CEILOMETER_DBPASS=$(openssl rand -hex 10)
export CEILOMETER_PASS=$(openssl rand -hex 10)
export TROVE_DBPASS=$(openssl rand -hex 10)
export TROVE_PASS=$(openssl rand -hex 10)
EOF

echo "Generated $out"
