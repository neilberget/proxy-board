Proxy = require("../proxy")

Chaos =
  pre: (req, next) ->
    console.log "CHAOS MODE!!!"
    next() unless @chaos()
    # console.log("Chaos!")

    # res.writeHead(500, {})
    # res.end("Chaos mode...")

    # true

  chaos: ->
    false
    # randNum = Math.random()
    # 
    # randNum < parseFloat("0.5")

module.exports = Chaos
