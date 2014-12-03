XProxyHost =
  pre: (req, next, stop) ->
    if req.headers['X-Proxy-Host']
      host = req.headers['X-Proxy-Host']
      req.url = "new-url"
    next(req)

module.exports = XProxyHost
