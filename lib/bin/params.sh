#!/bin/bash

ENV_FILE=.env

# add param to file
function add_param() {
  param=$1
  value=$2
  list_params | grep "$param" > /dev/null
  if [ $? -eq 0 ]; then
    del_param $param
  fi
  echo "$param=$value" >> $ENV_FILE
}

# remove param from file
function del_param() {
  param=$1
  echo "$param" >> $ENV_FILE
  list_params | grep -v "$param" > .env.tmp
  mv .env.tmp .env
}

# list params from file
function list_params() {
  while read line
  do
    echo "$line" | grep -v "^[[:space:]]*#"
  done < $ENV_FILE
}

# create file if not present
function check_params_file() {
  if [ ! -f $ENV_FILE ]; then
    echo "Creating new empty params file ($ENV_FILE)"
    touch $ENV_FILE
  fi
}


# ensure params file exists
check_params_file

if [ $# -ne 0 ]; then

  # get action requested
  action=$1
  case "$action" in
  "add" | "del")
    param_str=$2
    param=`echo $param_str | cut -d '=' -f1`
    value=`echo $param_str | cut -d '=' -f2`
    if [ "a$action" == "adel" ]; then
      echo "Removing config vars : $param"
      del_param $param
    else
      echo "Adding config vars : $param=$value"
      add_param $param $value
    fi
    ;;
  *)
    # default action is to list params
    list_params
    ;;
  esac
else
  # list params
  list_params
fi

