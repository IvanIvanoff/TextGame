#!/bin/bash


# ivan tapak, tova ne export-va v enviroment-a na call processa..............

if [[ $# -eq 1 ]]; then
  export TG_CLIENT_NAME=$1
else
  export TG_CLIENT_NAME=unknown
fi
