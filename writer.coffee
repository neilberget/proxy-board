zlib = require('zlib')

module.exports = (model) ->

  pre: (req, next) ->
    @start = new Date().getTime()
    next()

  post: (transaction, res, next) ->
    @end = new Date().getTime()

    console.log transaction.res.headers
    if transaction.res.headers?['content-encoding'] == 'gzip'
      console.log "unzip!!!!"
      res_body = zlib.inflate(transaction.res.body).toString('utf8')
    else
      res_body = transaction.res.body
    console.log res_body


    # TODO: if response header
    # save request details
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
    console.log request_data

    model.create(request_data).success( ->
      console.log "Request successfully captured"
    ).error (err) ->
      console.log err

    next()
