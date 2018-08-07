#!/bin/sh
set -e

main () (
  sudo docker run \
    --name radarmatic \
    --publish 127.0.0.1:3000:3000 \
    --restart always \
    --detach \
    jstn/radarmatic
)

main "$@"
