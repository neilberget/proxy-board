util         = require("util")
request      = require("request")
EventEmitter = require("events").EventEmitter

allowedHeaders = [
  "Authorization"
  "Content-Type"
  "X-Requested-With"
  "X-Proxy-Host"
]

# Given a target, get the host
# E.g. https://snapshot.edmodo.com/v1 => snapshot.edmodo.com
calculateHost = (target) ->
  host = target.replace("https://", "").replace("http://", "")
  host = host.substr(0, host.lastIndexOf("/"))  if host.lastIndexOf("/") > -1
  host

# Node lowercases headers
# attempt to undo that
prepareRequestHeaders = (reqHeaders, host) ->
  headers = {}
  toUpper = (a) -> a.toUpperCase()

  for i of reqHeaders
    h = i.replace(/^[a-z]|-[a-z]/g, toUpper)
    headers[h] = reqHeaders[i]
    # Set the Host request header to the ultimate destination
    # and not the proxy
    headers[h] = host  if h is "Host"
  headers

class Transaction
  counter: 0

  constructor: (@options) ->
    @options.rejectUnauthorized = false
    @url = @options.url
    @req = options.req
    @req.headers = options.headers
    @options.req.body = @options.body
    @proxy_id = @options.proxy_id

  perform: (@final_callback, @stop_callback) ->
    @pre => @deliver()

  deliver: ->
    request @options, (err, @res, @body) =>
      if err
        console.log "ERROR: " + err
        return

      @res.body = @body
      @post(@final_callback)

  pre: (cb) ->
    if @options.middleware[@counter]
      if @options.middleware[@counter].pre?
        next = (@options=@options) =>
          @counter++
          #@options = new_options
          @pre(cb)

        @options.middleware[@counter].pre @options, next, @stop_callback
      else
        @counter++
        @pre(cb)
    else
      @counter = 0
      cb(@options)

  post: (cb) ->
    if @options.middleware[@counter]
      if @options.middleware[@counter].post?
        @options.middleware[@counter].post @, @res, =>
          @counter++
          @post(cb)
      else
        @counter++
        @post(cb)
    else
      cb(@res, @body)


Proxy = (config) ->
  EventEmitter.call @

  @express_middleware = (target) =>
    (req, res, next) =>
      if req.method is "OPTIONS"
        res.setHeader "Access-Control-Allow-Origin", req.headers.origin
        res.setHeader "Access-Control-Allow-Headers", allowedHeaders.join(", ")
        res.setHeader "Access-Control-Allow-Credentials", "true"
        res.end()
      else
        @process target, req, res
  

  @process = (proxy, req, res, body) ->
    target = proxy.target
    path = req.url
    host = calculateHost(target)
    console.log "PROXY to " + target + path

    res.setHeader "Access-Control-Allow-Origin", req.headers.origin
    res.setHeader "Access-Control-Allow-Headers", allowedHeaders.join(", ")
    res.setHeader "Access-Control-Allow-Credentials", "true"
    
    # x-proxy-host (in middleware)
    targetUrl = target + path
    console.log "target url = #{targetUrl}"
    headers = prepareRequestHeaders(req.headers, host)

    final = (response, body) ->
      for key of response.headers
        res.setHeader key, response.headers[key]

      res.statusCode = response.statusCode
      res.end body

    stop = (status, body) ->
      res.statusCode = status
      res.end body

    console.log "starting transaction to " + targetUrl
    transaction = new Transaction
      proxy_id: proxy.id
      req:     req
      res:     res
      url:     targetUrl
      method:  req.method
      qs:      req.query
      headers: headers
      body:    body
      middleware: config.middleware

    transaction.perform(final, stop)
      
    return

  return

Proxy.router = (ProxyModel, RequestModel) ->
  proxy = new Proxy
    middleware: [
      # require("./proxy/middleware/chaos")(chaosRules)
      # require("./proxy/middleware/x_proxy_host")
      require("./middleware/no_gzip")
      require("../writer")(RequestModel)
    ]

  (req, res, next) ->
    host = req.headers.host

    proxy_request = (secure_id) ->
      body = ""
      req.on "data", (data) ->
        console.log "data = #{data}"
        body += data

      req.on "end", =>
        ProxyModel.find(
          where:
            secure_id: secure_id
        ).success (proxy_row) ->
          unless proxy_row
            next()
            return
          proxy.process(proxy_row, req, res, body)

    if req.headers['x-proxy-board']
      proxy_request req.headers['x-proxy-board']

    else if host.split('.').length == 3
      subdomain = host.split('.')[0]
      proxy_request subdomain

    else
      next()

    return

util.inherits Proxy, EventEmitter
module.exports = Proxy
