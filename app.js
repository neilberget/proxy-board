var express = require('express');
var mysql = require('mysql');
var beautify = require('js-beautify').js_beautify;
var hljs = require('highlight.js');


// Instantiating of processes
var ENV = (process.env['NODE_ENV'] || 'development').toLowerCase();
var config = require('./config/config')[ENV];
var app = express();
var proxy_app = express();


// Setting up of the Database connections
var Sequelize     = require('Sequelize');
var proxiesSchema = require('./schema/proxiesSchema');
var requestSchema = require('./schema/requestSchema');

var dbSystem = new Sequelize(
  config.database.database, 
  config.database.user, 
  config.database.password, { 
    dialect: 'mysql',
    define: {
      underscored: true
    },
    logging: false    
  }
);

ProxyModel    = dbSystem.define('proxies', proxiesSchema);
RequestModel  = dbSystem.define('requests', requestSchema);
dbSystem.sync();

var Proxy = require('./proxy');
var proxy = new Proxy();

// proxy.on("request:before", function(requestOptions) {
//   console.log("About to make request");
// });
proxy.on("request:complete", function(requestData) {
  RequestModel.create(requestData).success(function() {
    console.log("Request successfully captured");
  }).error(function(err) {
    console.log(err);
  });
});


app.configure(function() {
  app.use(express.bodyParser());
  app.use(express.errorHandler());
  app.use('/assets', express.static(__dirname + '/assets'));
});

proxy_app.configure(function() {
  proxy_app.use(proxy.middleware(config.proxy_to));
});

app.engine('html', require('ejs').renderFile);

app.get('/', function(req, res) {

  ProxyModel.findAll({ order: 'id DESC' }).success(function(results){
    res.render('index.html', { proxies: results });
  });

});

app.get('/proxy/:id', function(req, res) {

  RequestModel.findAll({ 
    order: 'id DESC',
    where: { proxy_id: req.params.id }

  }).success(function(results) {
    res.render('proxy.html', { requests: results });

  });
});

app.get('/request/:id', function(req, res) {

  RequestModel.findAll({ 
    where: { id: req.params.id }

  }).success(function(results) {
    var request = results[0]
    request.request_headers = JSON.parse(request.request_headers);
    request.request_body_beautified = hljs.highlightAuto(beautify(decodeURIComponent(request.request_body), { indent_size: 2 })).value;
    request.response_body_beautified = hljs.highlightAuto(beautify(request.response_body, { indent_size: 2 })).value;
    request.response_headers = JSON.parse(request.response_headers);
    res.render('request.html', { request: request });
    
  });
});

app.get('/response_body/:id', function(req, res) {

  RequestModel.findAll({ 
    where: { id: req.params.id }

  }).success(function(results) {
    res.end(results[0].response_body);
  });
});


module.exports = {
  app :           app,
  proxy_app:      proxy_app,
  proxy_model:     ProxyModel,
  request_model:  RequestModel,
  database_conn:  dbSystem
}
  
if(!module.parent) {
  var server = app.listen(3001, function() {
    console.log("Listening on port %d", server.address().port);
  });

  var proxy_server = proxy_app.listen(3002, function() {
    console.log("Proxy listening on port %d", proxy_server.address().port);
  });
}



// var io = require('socket.io').listen(server);

//io.sockets.on('connection', function (socket) {
//  socket.emit('news', { hello: 'world' });
//  socket.on('my other event', function (data) {
//    console.log(data);
//  });
//});
