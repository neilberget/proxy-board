To run:

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
