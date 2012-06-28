#!/bin/bash

ENV_FILE=.env

function add_param() {
  param=$1
  value=$2
  list_params | grep "$param" > /dev/null
  if [ $? -ne 0 ]; then
    echo "$param=$value" >> $ENV_FILE
  fi
}

function del_param() {
  param=$1
  echo "$param" >> $ENV_FILE
  list_params | grep -v "$param" > .env.tmp
  mv .env.tmp .env
}

function list_params() {
  while read line
  do
    echo "$line" | grep -v "^[[:space:]]*#"
  done < $ENV_FILE
}

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

