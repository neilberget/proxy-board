var express = require('express');
var request = require('request')
var mysql = require('mysql');

var app = express();

var config = {
  proxy_to: "http://localhost:3000"
};

var db = mysql.createConnection({
  host     : '127.0.0.1',
  user     : 'root',
  password : '',
  database : 'proxy_board'
});

db.connect(function(err) {
  if (err) {
    console.log("DB connect failed")
  }
});



var allowedHeaders = [
	"Authorization",
	"Content-Type",
	"X-Requested-With",
	"X-Proxy-Host"
];

var proxy = function(target, req, res) {
  var path = req.path.substr(6);
  console.log("PROXY to " + target + path);

  res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
  res.setHeader("Access-Control-Allow-Headers", allowedHeaders.join(", "));
  res.setHeader("Access-Control-Allow-Credentials", "true");

  // x-proxy-host

  targetUrl = target + path;
  var options = {
    url: targetUrl,
    method: req.method,
    qs: req.query,
    headers: req.headers,
    body: ""
  };
  req.on("data", function(data) {
    console.log("BODY: " + data);
    options.body += data;
  });
  req.on("end", function() {
    var startTime = new Date().getTime();
    request(options, function(err, response, body) {
      var totalTime = new Date().getTime() - startTime;
      for (var key in response.headers) {
        res.setHeader(key, response.headers[key]);
      }
      res.statusCode = response.statusCode;
      res.end(body);

      // save request details
      var request = {
        method: req.method,
        url:    target + req.url.substr(6), //targetUrl,
        request_headers: JSON.stringify(req.headers), // !!
        request_body: options.body,       // !!
        response_status: response.statusCode,
        response_headers: JSON.stringify(response.headers),
        response_body: body, // !!
        request_time_ms: totalTime,
        response_length_bytes: body.length
      };
  
      db.query("INSERT INTO requests SET ?", request, function(err, result) {
        if (err) {
          console.log(err);
        }
      });
    });
  });
};

var proxyMiddleware = function(target) {
  return function(req, res, next) {
    if(req.url.match(new RegExp('^\/proxy\/'))) {
      if (req.method == "OPTIONS") {
        res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
        res.setHeader("Access-Control-Allow-Headers", allowedHeaders.join(", "));
        res.setHeader("Access-Control-Allow-Credentials", "true");
        res.end();
      } else {
        //proxyReq = req
        //proxyReq.url = proxyReq.url.substr(6)
        proxy(target, req, res);
      }
    } else {
      next();
    }
  }
}

app.configure(function() {
  app.use(proxyMiddleware(config.proxy_to));
  app.use(express.bodyParser());
  app.use(express.errorHandler());
  app.use('/assets', express.static(__dirname + '/assets'));
});

app.engine('html', require('ejs').renderFile);

app.get('/', function(req, res) {
  db.query('SELECT * FROM requests ORDER BY id DESC', function(err, results) {
    res.render('index.html', { requests: results });
  });
});

app.get('/request/:id', function(req, res) {
  db.query('SELECT * FROM requests WHERE id=?', req.params.id, function(err, results) {
    res.render('request.html', { request: results[0] });
  });
});

app.get('/response_body/:id', function(req, res) {
  db.query('SELECT * FROM requests WHERE id=?', req.params.id, function(err, results) {
    res.end(results[0].response_body);
  });
});

var server = app.listen(3001, function() {
  console.log("Listening on port %d", server.address().port);
});

// var io = require('socket.io').listen(server);

//io.sockets.on('connection', function (socket) {
//  socket.emit('news', { hello: 'world' });
//  socket.on('my other event', function (data) {
//    console.log(data);
//  });
//});
