#!/bin/bash

# ivan tapak. tova ne exportva v parent enviromenta....


if [[ $# -ne 2 ]]; then
  export TG_SERVER_NAME=tg_server
  export TG_SERVER_LOCATION=127.0.0.1
else
  export TG_SERVER_NAME=${1}
  export TG_SERVER_LOCATION=${2}
fi
