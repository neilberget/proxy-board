# Chaos Middleware
# Forces a 500 response a percentage of the time based on provided rules
#
# To use:
# rules = [
#   { path: ".*test.*", failure_rate: "0.5" }
# ]
# proxy = new Proxy
#   middleware: [
#     require("./proxy/middleware/chaos")(rules)
#   ]
# 

module.exports = (rules) ->

  pre: (req, next, stop) ->
    if @chaos(req.url)
      console.log "CHAOS MODE!!!"
      stop(500, 'Chaos..')
    else
      next()

  chaos: (url) ->
    for rule in rules
      if url.match rule.path
        randNum = Math.random()
        return true if randNum < parseFloat(rule.failure_rate)

    false
