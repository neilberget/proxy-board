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

Proxy = ->
  _proxy = this
  EventEmitter.call @

  @middleware = (target) ->
    (req, res, next) ->
      if req.method is "OPTIONS"
        res.setHeader "Access-Control-Allow-Origin", req.headers.origin
        res.setHeader "Access-Control-Allow-Headers", allowedHeaders.join(", ")
        res.setHeader "Access-Control-Allow-Credentials", "true"
        res.end()
      else
        process target, req, res
  
  # var callbacks = {};
  
  # this.use = function(lifecycle, callback) {
  #   callbacks[lifecycle] ||= [];
  #   callbacks[lifecycle].push(callback);
  # };
  #
  process = (target, req, res) ->
    path = req.path
    host = calculateHost(target)
    console.log "PROXY to " + target + path
    res.setHeader "Access-Control-Allow-Origin", req.headers.origin
    res.setHeader "Access-Control-Allow-Headers", allowedHeaders.join(", ")
    res.setHeader "Access-Control-Allow-Credentials", "true"
    
    # x-proxy-host
    targetUrl = target + path
    headers = prepareRequestHeaders(req.headers, host)
    options =
      url:                targetUrl
      method:             req.method
      qs:                 req.query
      headers:            headers
      body:               ""
      rejectUnauthorized: false

    req.on "data", (data) ->
      options.body += data

    req.on "end", =>
      startTime = new Date().getTime()
      _proxy.emit "request:before", options
      request options, (err, response, body) ->
        if err
          console.log "ERROR: " + err
          return
        totalTime = new Date().getTime() - startTime
        for key of response.headers
          res.setHeader key, response.headers[key]
        res.statusCode = response.statusCode
        res.end body
        
        # save request details
        request_data =
          method: req.method
          url: target + req.url #targetUrl,
          request_headers: JSON.stringify(headers) # !!
          request_body: options.body # !!
          response_status: response.statusCode
          response_headers: JSON.stringify(response.headers)
          response_body: body # !!
          request_time_ms: totalTime
          response_length_bytes: body.length

        _proxy.emit "request:complete", request_data

    return
  return


util.inherits Proxy, EventEmitter
module.exports = Proxy
