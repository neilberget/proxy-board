#!/bin/bash

set -e

: ${PROXY_TO=https://appsapi.edmodoqa.com/v1}
: ${DB_HOST=127.0.0.1}
: ${DB_USER=root}
: ${DB_PASSWORD=}
: ${DB_NAME=proxy_board}

cat <<END
Be sure an ssh tunnel is in place to access the container:

    boot2docker ssh -fN -L 3001:localhost:3001 -L 3002:localhost:3002

    password: tcuser

END

docker stop proxy-board || true
docker rm proxy-board || true

docker run -d \
  -e "PROXY_TO=$PROXY_TO" \
  -e "DB_HOST=$DB_HOST" \
  -e "DB_USER=$DB_USER" \
  -e "DB_PASSWORD=$DB_PASSWORD" \
  -e "DB_NAME=$DB_NAME" \
  -p 3001:3001 \
  -p 3002:3002 \
  --name proxy-board \
  proxy-board
