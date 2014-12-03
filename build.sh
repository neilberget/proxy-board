#!/bin/bash

set -e
set -x

# if [ ! -f id_rsa ]
# then
#   echo "Please copy your id_rsa into this folder to build docker image"
#   echo "This is to allow npm access to private github repos"
#   exit
# fi

docker build -t registry.edmodo.io/proxy-board .
