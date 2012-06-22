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

# create a ruby template
# check foreman
#if [ -f $PWD/Procfile ]; then
#  bundle exec foreman export bluepill . --log "`pwd`/log/"
#fi

run deploy/before_restart | indent
run deploy/restart && run deploy/after_restart
