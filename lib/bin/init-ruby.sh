#!/usr/bin/env bash
#
# Purpose: install pre-requirements
# Usage: compile temporary_dir/ #cache_dir/#

# check for rbenv
if ! check_command rbenv; then
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

log "ruby version : `ruby -v`"
ruby ${BIN_DIR}/compile-ruby.rb
