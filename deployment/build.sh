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
  cd radarmatic || exit 1
  echo `git log --pretty=format:%h -n1` > public/version.txt
  rm -rf .git
  cd .. || exit 1
  sudo docker build --no-cache -t jstn/radarmatic .
  rm -rf radarmatic
)

main "$@"
