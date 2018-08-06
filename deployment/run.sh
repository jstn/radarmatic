#!/bin/sh
set -e

main () (
  cd docker || exit 1
  sudo /usr/local/bin/docker-compose up --detach
)

main "$@"
