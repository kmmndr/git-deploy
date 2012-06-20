#!/usr/bin/env bash
set -e
set -x
if [ "$GIT_DIR" = "." ]; then
  # The script has been called as a hook; chdir to the working copy
  cd ..
  GIT_DIR=.git
  export GIT_DIR
fi

FULL_DIR_NAME=$(/bin/pwd)
GIT_DIR_NAME=$(basename $FULL_DIR_NAME)
GIT_DIR_NAME=${GIT_DIR_NAME%.*}
BIN_DIR="${FULL_DIR_NAME}/.git/bin"
SCRATCH_DIR=/tmp/__git_deploy_scratch
CACHE_DIR=/tmp/__git_deploy_cache

echo "-----> $GIT_DIR_NAME app."

# try to obtain the usual system PATH
if [ -f /etc/profile ]; then
  PATH=$(source /etc/profile; echo $PATH)
  export PATH
fi

while read oldrev newrev refname
do
  if [ "$refname" != "refs/heads/master" ]; then
    echo "$refname is not master"
    continue
  fi
  rm -rf $SCRATCH_DIR/$GIT_DIR_NAME 
  mkdir -p $SCRATCH_DIR/$GIT_DIR_NAME $CACHE_DIR/$GIT_DIR_NAME
  GIT_WORK_TREE=$SCRATCH_DIR/$GIT_DIR_NAME git checkout -f $newrev &> /dev/null
  $BIN_DIR/detect $SCRATCH_DIR/$GIT_DIR_NAME
  $BIN_DIR/compile $SCRATCH_DIR/$GIT_DIR_NAME $CACHE_DIR/$GIT_DIR_NAME
done

echo "ref: refs/heads/master" > $GIT_DIR/HEAD

exit 0
