Proxy = require("../proxy")

Chaos =
  pre: (req, next, stop) ->
    console.log "CHAOS MODE!!!"
    if @chaos()
      stop(500, 'Chaos..')
    else
      next()

  chaos: ->
    randNum = Math.random()
    randNum < parseFloat("0.5")

module.exports = Chaos
