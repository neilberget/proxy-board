express  = require("express")
mysql    = require("mysql")
beautify = require("js-beautify").js_beautify
hljs     = require("highlight.js")

# Instantiating of processes
ENV = (process.env.NODE_ENV or "development").toLowerCase()
config = require("./config/config")[ENV]
app = express()
proxy_app = express()

# Setting up of the Database connections
Sequelize = require("Sequelize")
proxiesSchema = require("./schema/proxiesSchema")
requestSchema = require("./schema/requestSchema")

dbSystem = new Sequelize(config.database.database, config.database.user, config.database.password,
  dialect: "mysql"
  define:
    underscored: true

  logging: false
)

ProxyModel = dbSystem.define("proxies", proxiesSchema)
RequestModel = dbSystem.define("requests", requestSchema)
dbSystem.sync()

Proxy = require("./proxy")
proxy = new Proxy()

proxy.on "request:complete", (requestData) ->
  RequestModel.create(requestData).success( ->
    console.log "Request successfully captured"
  ).error (err) ->
    console.log err

app.configure ->
  app.use express.bodyParser()
  app.use express.errorHandler()
  app.use "/assets", express.static(__dirname + "/assets")

proxy_app.configure ->
  proxy_app.use proxy.middleware(config.proxy_to)

app.engine "html", require("ejs").renderFile

app.get "/", (req, res) ->
  ProxyModel.findAll(order: "id DESC").success (results) ->
    res.render "index.html",
      proxies: results

app.get "/proxy/:id", (req, res) ->
  RequestModel.findAll(
    order: "id DESC"
    where:
      proxy_id: req.params.id
  ).success (results) ->
    res.render "proxy.html",
      requests: results

app.get "/request/:id", (req, res) ->
  RequestModel.findAll(where:
    id: req.params.id
  ).success (results) ->
    request = results[0]
    request.request_headers = JSON.parse(request.request_headers)
    request.request_body_beautified = hljs.highlightAuto(beautify(decodeURIComponent(request.request_body),
      indent_size: 2
    )).value
    request.response_body_beautified = hljs.highlightAuto(beautify(request.response_body,
      indent_size: 2
    )).value
    request.response_headers = JSON.parse(request.response_headers)
    res.render "request.html",
      request: request

app.get "/response_body/:id", (req, res) ->
  RequestModel.findAll(where:
    id: req.params.id
  ).success (results) ->
    res.end results[0].response_body

module.exports =
  app:           app
  proxy_app:     proxy_app
  proxy_model:   ProxyModel
  request_model: RequestModel
  database_conn: dbSystem

unless module.parent
  server = app.listen 3001, ->
    console.log "Listening on port %d", server.address().port

  proxy_server = proxy_app.listen 3002, ->
    console.log "Proxy listening on port %d", proxy_server.address().port

# var io = require('socket.io').listen(server);

#io.sockets.on('connection', function (socket) {
#  socket.emit('news', { hello: 'world' });
#  socket.on('my other event', function (data) {
#    console.log(data);
#  });
#});
