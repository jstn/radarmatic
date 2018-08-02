#!/bin/sh
set -e

main () (
  cd docker || exit 1
  sudo docker-compose down
)

main "$@"
