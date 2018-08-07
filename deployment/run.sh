#!/bin/sh
set -e

main () (
  sudo docker run \
    --name radarmatic \
    --publish 172.31.83.116:3000:3000 \
    --restart always \
    --detach \
    jstn/radarmatic
)

main "$@"
