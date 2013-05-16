#!/usr/bin/env bash
#
# Purpose: check if the application is deployable
# Usage:  detect temporary_dir/

SRC_DIR=$1

# handle ruby project having a gemfile
if check_files $SRC_DIR Gemfile; then
  log "Ruby/* project detected"

  # loading selected ruby initializer
  initializer=$BIN_DIR/$INIT
  echo "initializer $initializer"
  if [ -x $initializer ]; then
    echo "INITIALIZATION RUBY"
    . $initializer
  else
    echo "INITIALIZATION RUBY NOT FOUND continuing with system ruby"
  fi

  log "ruby version : `ruby -v`"
  ruby ${BIN_DIR}/compile/ruby/compile.rb

  echo "HERE BEFORE"
  #return 1
fi
