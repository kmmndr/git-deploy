#!/usr/bin/env bash
#
# Purpose: check if the application is deployable
# Usage:  detect temporary_dir/ 

SRC_DIR=$1

# handle ruby project having a gemfile
if check_files $SRC_DIR Gemfile; then
  log "Ruby language detected"
  . $BIN_DIR/init-ruby.sh
fi
