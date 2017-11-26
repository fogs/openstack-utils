#!/bin/bash

mainDev=$(ip r|awk '/^default/{print $5}')
ip a show dev $mainDev | sed -n 's/[ \t]*inet \([0-9.]*\).*/\1/p'
