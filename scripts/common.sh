
os_cmd() {
  if [[ -z $SERVICE ]]; then
    echo "os_cmd needs SERVICE set"
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
      -f shell --prefix ${SERVICE}_${type}_${cmd}_ \
      "$@"
  )

}
