#!/usr/bin/env bash
set -e
if [ "$GIT_DIR" = "." ]; then
  # The script has been called as a hook; chdir to the working copy
  cd ..
  GIT_DIR=.git
  HOOKS_DIR=.git/hooks
  export GIT_DIR HOOKS_DIR
fi

###
#[ -e ${HOOKS_DIR}/pre-receive ] && mv -f ${HOOKS_DIR}/pre-receive ${HOOKS_DIR}/pre-receive.sample

if ! [ -t 0 ]; then
  read -a ref
fi
IFS='/' read -ra REF <<< "${ref[2]}"
CURRENT_GIT_BRANCH="${REF[2]}"
## get the current branch
#head="$(git symbolic-ref HEAD)"

FULL_DIRNAME=$(/bin/pwd)
PROJECT_NAME=$(basename $FULL_DIRNAME)
PROJECT_NAME=${PROJECT_NAME%.*}
BIN_DIR="${FULL_DIRNAME}/.git/bin"
export CURRENT_GIT_BRANCH FULL_DIRNAME PROJECT_NAME BIN_DIR

# loading functions
. $BIN_DIR/functions.sh

# abort if the push hasn't been done in master branch
if [ "$CURRENT_GIT_BRANCH" != "master" ]; then
  log "pushed into $CURRENT_GIT_BRANCH. Done."
  exit
fi

log "$PROJECT_NAME project"
log "deploying into $FULL_DIRNAME by user $USER"

PID=$$
log "Renice process ($PID)"
run_quietly "renice 19 -p $PID"

log "checking out latest push"
#run_quietly "mkdir -p ${CURRENT_RELEASE_APP_PATH}"
run_quietly "GIT_WORK_TREE=$FULL_DIRNAME git checkout -f"

. $BIN_DIR/detect.sh $FULL_DIRNAME
#. $BIN_DIR/compile $FULL_DIRNAME

log "DONE PREPARING :-)"

###

# try to obtain the usual system PATH
#if [ -f /etc/profile ]; then
#  PATH=$(source /etc/profile; echo $PATH)
#  export PATH
#fi

## read the STDIN to detect if this push changed the current branch
#while read oldrev newrev refname
#do
#  [ "$refname" = "$head" ] && break
#done
#
## abort if there's no update, or in case the branch is deleted
#if [ -z "${newrev//0}" ]; then
#  exit
#fi

# check out the latest code into the working copy
umask 002
#git reset --hard

logfile=log/deploy.log
restart=tmp/restart.txt

#if [ -z "${oldrev//0}" ]; then
  # this is the first push; this branch was just created
  mkdir -p log tmp
  chmod 0775 log tmp
  touch $logfile $restart
  chmod 0664 $logfile $restart

  # init submodules
  git submodule update --init | tee -a $logfile
#else
  # log timestamp
  echo "-----> ===[ $(date) ]===" >> $logfile

  # execute the deploy hook in background
  #[ -x deploy/after_push ] && nohup deploy/after_push $oldrev $newrev 1>>$logfile 2>>$logfile &
  [ -x deploy/after_push ] && . deploy/after_push $oldrev $newrev 2>&1 
#fi
