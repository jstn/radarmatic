#!/bin/sh
set -e

main () (
  if [ "$#" -ne 1 ]; then
    echo "Usage: ./run.sh <branchname>"
    exit 1
  fi

  sudo docker run \
    --name radarmatic \
    --publish 80:3000 \
    --restart always \
    --detach \
    jstn/radarmatic-"$1"
)

main "$@"
