Proxy = require("./proxy/proxy")

module.exports = (model) ->

  post: (transaction, res, next) ->
    console.log "Writing response"
    # save request details
    request_data =
      method: transaction.req.method
      url: transaction.url
      request_headers: JSON.stringify(transaction.req.headers) # !!
      request_body: transaction.req.body # !!
      response_status: transaction.res.statusCode
      response_headers: JSON.stringify(transaction.res.headers)
      response_body: transaction.res.body # !!
      request_time_ms: 0 # TODO: totalTime
      response_length_bytes: transaction.res.body.length

    model.create(request_data).success( ->
      console.log "Request successfully captured"
    ).error (err) ->
      console.log err

    next()
