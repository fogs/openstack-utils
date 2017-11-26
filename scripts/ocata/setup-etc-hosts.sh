#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 controllerIp"
  exit 1
fi

controllerIp=$1

if ! grep controller /etc/hosts > /dev/null; then
  echo "$controllerIp controller" >> /etc/hosts
fi
