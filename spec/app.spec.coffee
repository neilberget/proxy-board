request = require 'request'
Sequelize = require 'sequelize'

process.env['NODE_ENV'] = 'test'

proxy_board     = require '../app'
app_web         = proxy_board.app
app_proxy       = proxy_board.proxy_app
RequestModel    = proxy_board.request_model
ProxyModel      = proxy_board.proxy_model

test_server     = require './fixtures/test_server'

domain      = "http://localhost"
web_port    = 3001
proxy_port  = 3002
test_port   = 9999
web_url     = domain + ":" + web_port
proxy_url   = domain + ":" + proxy_port


describe "ProxyBoard", ->
  beforeEach (done)->
    @ts  = test_server.listen test_port    
    @aw  = app_web.listen web_port
    @ap  = app_proxy.listen proxy_port

    chainer = new Sequelize.Utils.QueryChainer()
      .add(RequestModel.sync({force: true}))
      .add(ProxyModel.sync({force: true}))
      .run()
      .success ()=>
        done()

  afterEach (done)->
    @ts.close()    
    @aw.close()
    @ap.close()
    done()

  describe "POST METHODS", ->
  
    it "should create a request record for GET ", (done)->
      console.log proxy_url
      options =
        url: proxy_url
        method: "POST"
        body:  "This is the body"

      request.post options, (error, response, body)=>
        RequestModel
          .findAll()
          .success (results)=>
            expect(results.length).toEqual 1
            expect(results[0].url).toEqual "http://localhost:9999/v1/"
            expect(results[0].request_body).toEqual "This is the body"
            expect(results[0].method).toEqual "POST"
            response = JSON.parse results[0].response_body
            expect(response.status).toEqual "SUCCESS"
            expect(response.method).toEqual "POST"            
            done()
    
  describe "GET METHODS", ->

    it "should create a request record for GET ", (done)->
      options =
        url: proxy_url
        method: "GET"
        qs: 
          this: "is"
          fun: "how"

      request options, (error, response, body)=>
        RequestModel
          .findAll()
          .success (results)=>
            expect(results.length).toEqual 1
            expect(results[0].url).toEqual "http://localhost:9999/v1/?this=is&fun=how"
            expect(results[0].method).toEqual "GET"
            response = JSON.parse results[0].response_body
            expect(response.status).toEqual "SUCCESS"
            expect(response.method).toEqual "GET"
            done()