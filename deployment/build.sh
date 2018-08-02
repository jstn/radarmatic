#!/bin/sh
set -e

main () (
  if [ "$#" -ne 1 ]; then
    echo "Usage: ./build.sh <branchname>"
    exit 1
  fi

  BRANCH="$1"

  cd docker || exit 1
  rm -rf radarmatic
  git clone -b "$BRANCH" https://github.com/jstn/radarmatic.git radarmatic --depth 1
  rm -rf radarmatic/.git* radarmatic/deployment
  sudo docker build -t jstn/radarmatic .
  rm -rf radarmatic
)

main "$@"
