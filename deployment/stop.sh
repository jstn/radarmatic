#!/bin/sh
set -e

main () (
  sudo docker stop radarmatic
  sudo docker rm radarmatic
)

main "$@"
