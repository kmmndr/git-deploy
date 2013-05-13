#!/usr/bin/env bash
#
# Purpose: check if the application is deployable
# Usage:  detect temporary_dir/ 

SRC_DIR=$1

# handle ruby project having a gemfile
if check_files $SRC_DIR Gemfile; then
  log "Ruby/* project detected"

  # loading selected ruby initializer
  if [ -x $BIN_DIR/init/ruby ]; then
    . $BIN_DIR/init/ruby
  fi

  #. $BIN_DIR/init/chruby.sh

  log "ruby version : `ruby -v`"
  #ruby ${BIN_DIR}/compile-ruby.rb

  env
fi
