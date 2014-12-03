express  = require("express")
mysql    = require("mysql")
beautify = require("js-beautify").js_beautify
hljs     = require("highlight.js")
Docker   = require('dockerode')
docker = new Docker socketPath: '/var/run/docker.sock'

# Instantiating of processes
ENV = (process.env.NODE_ENV or "development").toLowerCase()
config = require("./config/config")[ENV]
app = express()
proxy_app = express()

# Setting up of the Database connections
Sequelize = require("sequelize")
proxiesSchema = require("./schema/proxiesSchema")
requestSchema = require("./schema/requestSchema")

dbSystem = new Sequelize(config.database.database, config.database.user, config.database.password,
  dialect: "mysql"

  define:
    underscored: true

  host: config.database.host

  logging: false
)

ProxyModel = dbSystem.define("proxies", proxiesSchema)
RequestModel = dbSystem.define("requests", requestSchema)
dbSystem.sync()

chaosRules = [
  { path: ".*test.*", failure_rate: "0.5" }
]

Proxy = require("./proxy/proxy")
proxy = new Proxy
  middleware: [
    # require("./proxy/middleware/chaos")(chaosRules)
    # require("./proxy/middleware/x_proxy_host")
    require("./proxy/middleware/no_gzip")
    require("./writer")(RequestModel)
  ]

proxy_router = (req, res, next) ->
  host = req.headers.host

  if host.split('.').length == 3
    subdomain = host.split('.')[0]
    ProxyModel.find(
      where:
        secure_id: subdomain
    ).success (proxy_row) ->
      unless proxy_row
        next()
        return
      console.log proxy
      proxy.process(proxy_row, req, res)
  else
    next()

app.configure ->
  app.use express.json()
  app.use express.urlencoded()
  app.use express.errorHandler()
  app.use "/assets", express.static(__dirname + "/assets")
  app.use proxy_router

proxy_app.configure ->
  proxy_app.use proxy.express_middleware(config.proxy_to)

startProxyContainer = (proxy) ->
  vhost = "#{proxy.secure_id}.edmodo.io"
  containerName = "proxyboard-#{proxy.secure_id}"
  docker.getContainer(containerName).stop (err, data) ->
    console.log(err) if err

    docker.getContainer(containerName).remove (err, data) ->
      console.log(err) if err

      docker.run 'registry.edmodo.io/proxy-board', ['coffee', 'app.coffee'], null, {Env: "VIRTUAL_HOST=#{vhost}", Links:["mysql:mysql"], name: containerName}, (err, data, container) ->
        console.log err
      .on 'container', (container) ->
        container.defaultOptions.start.Links = ["mysql:mysql"]


initializeProxyContainers = ->
  # Launch all proxies on app launch
  ProxyModel.findAll(order: "id DESC").success (results) ->
    results.forEach startProxyContainer

initializeProxyContainers()

app.engine "html", require("ejs").renderFile

app.get "/", (req, res) ->
  ProxyModel.findAll(order: "id DESC").success (results) ->
    res.render "index.html",
      proxies: results

app.get "/proxy/new", (req, res) ->
  res.render "proxy/new.html"

app.post "/proxy", (req, res) ->
  data = req.body
  data.user_id = 1

  ProxyModel.create(data).success (proxy) ->
    startProxyContainer(proxy)
    res.redirect '/'

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
  server = app.listen 80, ->
    console.log "Listening on port %d", server.address().port

  # proxy_server = proxy_app.listen 80, ->
  # prconsole.log "Proxy listening on port %d", proxy_server.address().port


# io = require('socket.io').listen(server)
# 
# io.sockets.on 'connection', (socket) ->
#   socket.emit 'news', hello: 'world'
#   socket.on 'my other event', (data) ->
#     console.log data
