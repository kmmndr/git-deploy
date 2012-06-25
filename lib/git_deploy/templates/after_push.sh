#!/usr/bin/env bash
set -e
oldrev=$1
newrev=$2

indent() {
  sed -u 's/^/       /'
}

run() {
  [ -x $1 ] && $1 $oldrev $newrev
}

echo "-----> files changed: $(git diff $oldrev $newrev --diff-filter=ACDMR --name-only | wc -l)"

umask 002

git submodule init && git submodule sync && git submodule update

# uncomment for ruby/rails deployment
#if [ -f $FULL_DIRNAME/Procfile ]; then
#  export RAILS_ENV=production
#  bundle exec foreman export bluepill $FULL_DIRNAME --user $USER --log "$FULL_DIRNAME/log/" -a $PROJECT_NAME -p 12000
#  bluepill load $FULL_DIRNAME/$PROJECT_NAME.pill --no-privileged
#fi

run deploy/before_restart | indent
run deploy/restart && run deploy/after_restart
