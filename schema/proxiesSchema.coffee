randVal = ->
  alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
  [1..6].map ->
    alphabet[Math.floor(Math.random() * alphabet.length)]
  .join ''

Sequelize = require('sequelize')

proxiesSchema =
  user_id: Sequelize.INTEGER

  target:
    type: Sequelize.TEXT
    set: (v) ->
      this.setDataValue('target', v)
      this.setDataValue('secure_id', randVal())

  secure_id: Sequelize.STRING(12)

module.exports = proxiesSchema
