var config = {
  //proxy_to: "http://localhost:3000"
  test: {
    proxy_to: "https://appsapi.edmodoqa.com",
    host: "appsapi.edmodoqa.com",
    database: {
      host     : '127.0.0.1',
      user     : 'root',
      password : '',
      database : 'proxy_board_test'
    }
  },
  development: {
    proxy_to: "https://appsapi.edmodoqa.com",
    host: "appsapi.edmodoqa.com",
    database: {
      host     : '127.0.0.1',
      user     : 'root',
      password : '',
      database : 'proxy_board'
    }    
  }

};

module.exports = config;