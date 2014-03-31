var Sequelize = require('sequelize');
var proxiesSchema = {
  user_id: Sequelize.INTEGER,  
  target: Sequelize.TEXT
}

module.exports = proxiesSchema;