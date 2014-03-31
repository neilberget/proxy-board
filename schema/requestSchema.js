var Sequelize = require('sequelize');
var requestsSchema = {
  proxy_id: Sequelize.INTEGER,  
  method: Sequelize.STRING(12),
  url: Sequelize.STRING,
  request_headers: Sequelize.TEXT,
  request_body: Sequelize.TEXT,
  response_status: Sequelize.STRING(12),
  response_headers: Sequelize.TEXT,
  response_body: Sequelize.TEXT,
  request_time_ms: Sequelize.INTEGER,  
  response_length_bytes: Sequelize.INTEGER
}

module.exports = requestsSchema;