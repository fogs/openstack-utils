#!/bin/bash

out=.credentials.sh

if [ -f $out ]; then
  echo "$out already exists" >&2
  exit 1
fi

read -s -p "MySQL root password: " mysql_pw
echo

cat > $out <<EOF
MYSQL_PASS=${mysql_pw}
RABBIT_PASS=$(openssl rand -hex 10)
KEYSTONE_DBPASS=$(openssl rand -hex 10)
DEMO_PASS=$(openssl rand -hex 10)
ADMIN_PASS=$(openssl rand -hex 10)
GLANCE_DBPASS=$(openssl rand -hex 10)
GLANCE_PASS=$(openssl rand -hex 10)
NOVA_DBPASS=$(openssl rand -hex 10)
NOVA_PASS=$(openssl rand -hex 10)
DASH_DBPASS=$(openssl rand -hex 10)
CINDER_DBPASS=$(openssl rand -hex 10)
CINDER_PASS=$(openssl rand -hex 10)
NEUTRON_DBPASS=$(openssl rand -hex 10)
NEUTRON_PASS=$(openssl rand -hex 10)
HEAT_DBPASS=$(openssl rand -hex 10)
HEAT_PASS=$(openssl rand -hex 10)
CEILOMETER_DBPASS=$(openssl rand -hex 10)
CEILOMETER_PASS=$(openssl rand -hex 10)
TROVE_DBPASS=$(openssl rand -hex 10)
TROVE_PASS=$(openssl rand -hex 10)
EOF

echo "Generated $out"
