#!/bin/sh
set -e

main () (
  sudo docker exec -t -i radarmatic bash -l
)

main "$@"
