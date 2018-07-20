#!/bin/sh
set -e

main () (
  if [ "$#" -ne 1 ]; then
    echo "Usage: ./run.sh <branchname>"
    exit 1
  fi

  BRANCH="$1"
  IP="172.31.3.224"
  PORT="80"

  sudo docker run \
    --name radarmatic \
    --hostname radarmatic.com \
    --publish "$IP":"$PORT":80 \
    --restart always \
    --detach \
    jstn/radarmatic-"$BRANCH"
)

main "$@"
