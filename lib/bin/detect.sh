#!/usr/bin/env bash
#
# Purpose: check if the application is deployable
# Usage:  detect temporary_dir/
SRC_DIR=$1

DETECT_DIR=$BIN_DIR/detect
#echo "$DETECT_DIR"

detector=$DETECT_DIR/$DETECT

not_found=1

#env
#echo "DETECT : $DETECT"
#echo "YO"

# OPTIMIZE : use original heroku build pack instead

if [ -x $detector ]; then
  . $detector $SRC_DIR
  not_found=$?
else
  if [ -d $DETECT_DIR ]; then
    for detector in $DETECT_DIR/*
    do
      echo "detector $detector found"
      . $detector $SRC_DIR
      not_found=$?
      [ $not_found -ne 0 ] && break
    done

    env
  fi
fi

if [ $not_found -ne 0 ]; then
  log "No language detector detected"
else
  # detector found
  echo "Detector found : $detector"
  echo "(Probably) Deployed successfully"
fi

exit
