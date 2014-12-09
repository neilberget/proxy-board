zlib = require('zlib')

module.exports = (model) ->

  pre: (req, next) ->
    @start = new Date().getTime()
    next()

  post: (transaction, res, next) ->
    @end = new Date().getTime()

    res_body = transaction.res.body

    request_data =
      proxy_id: transaction.proxy_id
      method: transaction.req.method
      url: transaction.url
      request_headers: JSON.stringify(transaction.req.headers)
      request_body: transaction.req.body
      response_status: transaction.res.statusCode
      response_headers: JSON.stringify(transaction.res.headers)
      response_body: res_body
      request_time_ms: @end - @start
      response_length_bytes: res_body.length

    model.create(request_data).success( ->
      console.log "Request successfully captured"
    ).error (err) ->
      console.log err

    next()
