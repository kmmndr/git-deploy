#!/usr/bin/env bash
#
# Purpose: install pre-requirements
# Usage: compile temporary_dir/ #cache_dir/#

# check for rbenv
if [[ ! $RBENV_PATH ]]; then
  RBENV_PATH="$HOME/.rbenv"
fi
log "RBENV_PATH : $RBENV_PATH"

run_quietly "[ -d $RBENV_PATH ] && export PATH=\"$RBENV_PATH/bin:$PATH\" && eval \"\$(rbenv init - sh)\" && rbenv rehash"
log "ruby version : `ruby -v`"

if ! check_command rbev; then
  exit_with_error "rbenv"
  #sudo gem install bundler --pre | indent
fi


