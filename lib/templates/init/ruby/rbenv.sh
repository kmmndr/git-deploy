#!/usr/bin/env bash
#
# Purpose: load ruby interpretor

# check for rbenv
if ! check_command rbenv; then
  # if rbenv isn't a system command (it has been added into debian wheezy)
  if [[ ! $RBENV_PATH ]]; then
    RBENV_PATH="$HOME/.rbenv"
  fi
  if [ -d $RBENV_PATH ]; then
    log "RBENV_PATH : $RBENV_PATH"
    run_quietly "[ -d $RBENV_PATH ] && export PATH=\"$RBENV_PATH/bin:$PATH\" && eval \"\$(rbenv init - sh)\" && rbenv rehash"

    # re-check
    if ! check_command rbenv; then
      exit_with_error "rbenv"
    fi
  fi
fi
