express  = require("express")
mysql    = require("mysql")
beautify = require("js-beautify").js_beautify
hljs     = require("highlight.js")
Docker   = require('dockerode')
docker = new Docker socketPath: '/var/run/docker.sock'
moment = require('moment');

# Instantiating of processes
ENV = (process.env.NODE_ENV or "development").toLowerCase()
config = require("./config/config")[ENV]
app = express()

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

app.use Proxy.router(ProxyModel, RequestModel)
# app.use express.json()
# app.use express.urlencoded()
# app.use express.errorHandler()
app.use "/assets", express.static(__dirname + "/assets")

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
    results = results.map (result) ->
      result.time_ago = moment(result.created_at).fromNow()
      result

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
  proxy_model:   ProxyModel
  request_model: RequestModel
  database_conn: dbSystem


startDashboard = ->
  server = app.listen 3001, ->
    console.log "Listening on port %d", server.address().port

    #   startProxyContainer = (proxy) ->
    #     vhost = "#{proxy.secure_id}.edmodo.io"
    #     containerName = "proxyboard-#{proxy.secure_id}"
    #     docker.getContainer(containerName).stop (err, data) ->
    #       console.log(err) if err
    # 
    #       docker.getContainer(containerName).remove (err, data) ->
    #         console.log(err) if err
    # 
    #         docker.run 'registry.edmodo.io/proxy-board', ['coffee', 'app.coffee'], null, {Env: "VIRTUAL_HOST=#{vhost}", Links:["mysql:mysql"], name: containerName}, (err, data, container) ->
    #           console.log err
    #         .on 'container', (container) ->
    #           container.defaultOptions.start.Links = ["mysql:mysql"]


unless module.parent
  startDashboard()
