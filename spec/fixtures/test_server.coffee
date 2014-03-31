express = require 'express'

app = express()
app.configure ()->
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use(app.router)

app.post '/v1', (req, res)->
  res.send { status: "SUCCESS", method: "POST" }

app.get '/v1', (req, res)->
  res.send { status: "SUCCESS", method: "GET" }

exports = module.exports = app

if !module.parent
  console.log 'Testing server listening at port 9999'
  app.listen 9999