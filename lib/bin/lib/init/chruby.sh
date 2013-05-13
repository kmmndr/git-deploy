#!/usr/bin/env bash
#
# Purpose: load ruby interpretor

echo "here"

# check for chruby
if ! check_command chruby; then
  CHRUBY_LOADER=/usr/local/share/chruby/chruby.sh
  CHRUBY_AUTO=/usr/local/share/chruby/auto.sh

  if [ -f $CHRUBY_LOADER ]; then
    log "LOADING CHRUBY"
    run_quietly "source $CHRUBY_LOADER"
    # OPTIMIZE : use CHRUBY_AUTO if possible
    if [ -f $CHRUBY_AUTO ]; then
      log "LOADING CHRUBY AUTO"
      run_quietly "source $CHRUBY_AUTO"
      run_quietly "chruby `cat .ruby-version`"
    fi

    # re-check
    if ! check_command chruby; then
      exit_with_error "chruby"
    fi
  fi
fi


