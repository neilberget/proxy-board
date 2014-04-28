o run:

Create a database called proxy\_board with the db/proxy\_board.sql schema

Edit the config.proxy_to setting in app.js

    npm install
    node app

Go to http://localhost:3001 to see your dashboard

Any requests routed through http://localhost:3002/ will be recorded.

# Unit Testing

Setting up

    npm install jasmine-node -g
    npm install coffee-script -g

Create `proxy_board_test`

running unit test

    jasmine-node --coffee spec/






Docker
----
Set up boot2docker and docker on OS X:
http://docs.docker.io/installation/mac/

If you run into a port in use error:
https://gist.githubusercontent.com/ahbeng/9065790/raw/c8a3a4e23f28618f1645f0f7bba9070230a67c86/change_crashplan_backup_service_port.sh
