

echo "Setting up $desc ($service_name)"

os_cmd() {
  if [[ -z $service_name ]]; then
    echo "os_cmd needs service_name set"
    exit 100
  fi
  if [[ $# -lt 2 ]]; then
    echo "os_cmd invoked with not enough args"
    exit 100
  fi

  type=$1
  cmd=$2
  shift 2

  eval $(
    openstack $type $cmd \
      -f shell --prefix ${service_name}_${type}_${cmd}_ \
      "$@"
  )

}
