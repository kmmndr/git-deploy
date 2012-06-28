#!/usr/bin/env bash
#
# Purpose: install pre-requirements
# Usage: compile temporary_dir/ #cache_dir/#

# check for rbenv
if ! check_command rbenv; then
  # if rbenv isn't a system command (it has been added into debian wheezy)
  if [[ ! $RBENV_PATH ]]; then
    RBENV_PATH="$HOME/.rbenv"
  fi
  log "RBENV_PATH : $RBENV_PATH"

  run_quietly "[ -d $RBENV_PATH ] && export PATH=\"$RBENV_PATH/bin:$PATH\" && eval \"\$(rbenv init - sh)\" && rbenv rehash"

  # re-check
  if ! check_command rbenv; then
    exit_with_error "rbenv"
  fi
fi

# need better place
#export DATABASE_URL="postgres://$PROJECT_NAME:$PROJECT_NAME@localhost/$PROJECT_NAME"

log "ruby version : `ruby -v`"
ruby ${BIN_DIR}/compile-ruby.rb

env

