#!/usr/bin/env bash

run_quietly() {
  #eval $1 | indent || exit_with_error $1
  eval $1 || exit_with_error $1
}

run() {
  echo "running : $1"
  run_quietly "$1"
}

log() {
  echo "-----> $*"
}

indent() {
  sed -u 's/^/       /'
}

check_command() {
  command -v $1 > /dev/null
}

check_files() {
  folder=$1
  shift
  while (( "$#" )); do
    if [ ! -f $folder/$1 ]; then
      return 1
    fi
    shift
  done
  return 0
}

exit_with_error() {
  log "An error has occurred, stopping\nInvoked command : $1"
  exit 1
}

USER=`id -nu`

