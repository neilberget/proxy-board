NoGzip =
  pre: (req, next, stop) ->
    req.headers['Accept-Encoding'] = 'identity'
    next(req)

module.exports = NoGzip
