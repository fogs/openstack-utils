#!/bin/bash

if [ $# -lt 4 ]; then
  echo "Usage: $0 file section key value [key value]..." >&2
  exit 1
fi

file=$1
section=$2
shift 2

get_existing() {
  file=$1
  section=$2
  key=$3

  awk -f - $file <<EOF
  !within && /^\[$section\]/ {
    within = 1
    matched = 0
    next
  }

  within && /^\[.+\]/ {
    if (!matched) {
      print "NOT FOUND"
    }
    within = 0
    next
  }

  within && /\s*#\s*$key\s*=/ {
    print
    matched = 1
    next
  }

  within && /\s*$key\s*=/ {
    print
    matched = 1
    next
  }
EOF
}

replace() {
  fileIn=$1
  fileOut=$2
  section=$3
  key=$4
  value=$5

  existing=$(get_existing $fileIn $section $key)

  echo ""
  if [ $existing = 'NOT FOUND' ]; then
    echo "$key is not yet present"
    echo ""
    read -p "Add it with '$value' (y/n)? " -n 1
    echo ""
  else
    echo "Current value:"
    echo $existing
    echo ""
    read -p "Replace with '$value' (y/n)? " -n 1
    echo ""
  fi

  if [ $REPLY != "y" -a $REPLY != "Y" ]; then
    return
  fi

  awk -f - $fileIn > $fileOut <<EOF

  !within && /^\[$section\]/ {
    print
    within = 1
    matched = 0
    next
  }

  within && /^\[.+\]/ {
    if (!matched) {
      print "$key=$value"
    }
    print
    within = 0
    next
  }

  within && /\s*#?\s*$key\s*=/ {
    print "$key=$value"
    matched = 1
    next
  }

  { print }

EOF

}

trap "rm /tmp/$$.out /tmp/$$.in" EXIT

if [ ${file:0:1} != / ]; then
  sep=/
fi
patchOut=
for ((i = 1; ; ++i)); do
  patchOut=patches${sep}${file}.${i}
  if [ ! -f $patchOut ]; then
    break
  fi
done

# Prep the result
cp $file "/tmp/$$.out"

while [ $# -ge 2 ]; do
  key=$1
  value=$2
  shift 2

  # Prep the replacement input
  cp "/tmp/$$.out" "/tmp/$$.in"
  replace "/tmp/$$.in" "/tmp/$$.out" $section $key $value
done

echo "Saved patch-to-revert in $patchOut"
mkdir -p $(dirname $patchOut)
diff -u "/tmp/$$.out" $file > $patchOut
cp "/tmp/$$.out" $file
