#!/bin/sh
set -e

main () (
  sudo docker run \
    --name radarmatic \
    --net=host \
    --restart always \
    --detach \
    jstn/radarmatic
)

main "$@"
