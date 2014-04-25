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
    @options.req.body = @options.body

  perform: (@final_callback) ->
    @pre => @deliver()

  deliver: ->
    request @options, (err, @res, @body) =>
      if err
        console.log "ERROR: " + err
        return
      #totalTime = new Date().getTime() - startTime

      @res.body = @body
      @post(@final_callback)

  pre: (cb) ->
    if @options.middleware[@counter]
      if @options.middleware[@counter].pre?
        @options.middleware[@counter].pre @options, =>
          @counter++
          @pre(cb)
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
  _proxy = this
  EventEmitter.call @

  @express_middleware = (target) ->
    (req, res, next) ->
      if req.method is "OPTIONS"
        res.setHeader "Access-Control-Allow-Origin", req.headers.origin
        res.setHeader "Access-Control-Allow-Headers", allowedHeaders.join(", ")
        res.setHeader "Access-Control-Allow-Credentials", "true"
        res.end()
      else
        process target, req, res
  

  process = (target, req, res) ->
    path = req.path
    host = calculateHost(target)
    console.log "PROXY to " + target + path

    res.setHeader "Access-Control-Allow-Origin", req.headers.origin
    res.setHeader "Access-Control-Allow-Headers", allowedHeaders.join(", ")
    res.setHeader "Access-Control-Allow-Credentials", "true"
    
    final = (response, body) ->
      for key of response.headers
        res.setHeader key, response.headers[key]

      res.statusCode = response.statusCode
      res.end body

    # x-proxy-host
    targetUrl = target + path
    headers = prepareRequestHeaders(req.headers, host)
    body = ""
    # options =
    #   url:                targetUrl
    #   method:             req.method
    #   qs:                 req.query
    #   headers:            headers
    #   body:               ""
    #   rejectUnauthorized: false

    req.on "data", (data) ->
      body += data

    req.on "end", =>
      transaction = new Transaction
        req:     req
        res:     res
        url:     targetUrl
        method:  req.method
        qs:      req.query
        headers: headers
        body:    body
        middleware: config.middleware

      # startTime = new Date().getTime()

      # call pre-transform middlewares
      transaction.perform(final)
      #pre_transform(options, makeRequest)
      
    return

  return

# Lifecycle events
Proxy.BEFORE = "before"
Proxy.AFTER  = "after"


util.inherits Proxy, EventEmitter
module.exports = Proxy
