var express = require('express');
var request = require('request')
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

var allowedHeaders = [
	"Authorization",
	"Content-Type",
	"X-Requested-With",
	"X-Proxy-Host"
];

var proxy = function(target, req, res) {
  var path = req.path;
  console.log("PROXY to " + target + path);

  res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
  res.setHeader("Access-Control-Allow-Headers", allowedHeaders.join(", "));
  res.setHeader("Access-Control-Allow-Credentials", "true");

  // x-proxy-host

  targetUrl = target + path;

  var headers = {};
  for (var i in req.headers) {
    var h = i.replace(/^[a-z]|-[a-z]/g, function (a) {
      return a.toUpperCase();
    });
    headers[h] = req.headers[i];

    if (h == "Host") {
      headers[h] = config.host;
    }
  }

  var options = {
    url: targetUrl,
    method: req.method,
    qs: req.query,
    headers: headers,
    body: "",
    rejectUnauthorized: false
  };
  req.on("data", function(data) {
    options.body += data;
  });
  req.on("end", function() {
    var startTime = new Date().getTime();
    request(options, function(err, response, body) {
      if (err) {
        console.log("ERROR: " + err);
        return;
      }
      var totalTime = new Date().getTime() - startTime;
      for (var key in response.headers) {
        res.setHeader(key, response.headers[key]);
      }
      res.statusCode = response.statusCode;
      res.end(body);

      // save request details
      var request_data = {
        method: req.method,
        url:    target + req.url, //targetUrl,
        request_headers: JSON.stringify(headers), // !!
        request_body: options.body,       // !!
        response_status: response.statusCode,
        response_headers: JSON.stringify(response.headers),
        response_body: body, // !!
        request_time_ms: totalTime,
        response_length_bytes: body.length
      };

      RequestModel.create(request_data).success(function() {
        console.log("Request successfully captured");

      }).error(function(err) {
        console.log(err);

      });
    });
  });
};

var proxyMiddleware = function(target) {
  return function(req, res, next) {
    if (req.method == "OPTIONS") {
      res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
      res.setHeader("Access-Control-Allow-Headers", allowedHeaders.join(", "));
      res.setHeader("Access-Control-Allow-Credentials", "true");
      res.end();
    } else {
      proxy(target, req, res);
    }
  }
}

app.configure(function() {
  app.use(express.bodyParser());
  app.use(express.errorHandler());
  app.use('/assets', express.static(__dirname + '/assets'));
});

proxy_app.configure(function() {
  proxy_app.use(proxyMiddleware(config.proxy_to));
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
    request.request_body_beautified = hljs.highlightAuto(beautify(request.request_body, { indent_size: 2 })).value;
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
