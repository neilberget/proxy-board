var config = {
  //proxy_to: "http://localhost:3000"
  test: {
    proxy_to: "http://localhost:9999/v1",
    host: "localhost:9999",
    database: {
      host     : '127.0.0.1',
      user     : process.env.DB_USER || 'root',
      password : process.env.DB_PASSWORD || '',
      database : 'proxy_board_test'
    }
  },
  development: {
    proxy_to: process.env.PROXY_TO || "https://appsapi.edmodoqa.com/v1",
    database: {
      host     : process.env.DB_HOST     || '127.0.0.1',
      user     : process.env.DB_USER     || 'root',
      password : process.env.DB_PASSWORD || '',
      database : process.env.DB_NAME     || 'proxy_board'
    }    
  }

};

module.exports = config;
