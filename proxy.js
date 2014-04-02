var util = require('util');
var request = require('request');
var EventEmitter = require('events').EventEmitter;

var allowedHeaders = [
  "Authorization",
  "Content-Type",
  "X-Requested-With",
  "X-Proxy-Host"
 ];

// Given a target, get the host
// E.g. https://snapshot.edmodo.com/v1 => snapshot.edmodo.com
var calculateHost = function(target) {
  var host = target.replace("https://", "").replace("http://", "");
  if (host.lastIndexOf("/") > -1) {
    host = host.substr(0, host.lastIndexOf("/"));
  }
  return host;
};

var prepareRequestHeaders = function(reqHeaders, host) {
  var headers = {};

  // Node lowercases headers
  // attempt to undo that
  for (var i in reqHeaders) {
    var h = i.replace(/^[a-z]|-[a-z]/g, function (a) {
      return a.toUpperCase();
    });
    headers[h] = reqHeaders[i];

    // Set the Host request header to the ultimate destination
    // and not the proxy
    if (h == "Host") {
      headers[h] = host;
    }
  }

  return headers;
}

function Proxy() {
  var _this = this;

  EventEmitter.call(this);

  this.middleware = function(target) {
    return function(req, res, next) {
      if (req.method == "OPTIONS") {
        res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
        res.setHeader("Access-Control-Allow-Headers", allowedHeaders.join(", "));
        res.setHeader("Access-Control-Allow-Credentials", "true");
        res.end();
      } else {
        process(target, req, res);
      }
    };
  };

  var process = function(target, req, res) {
    var path = req.path;
    var host = calculateHost(target)

    console.log("PROXY to " + target + path);

    res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
    res.setHeader("Access-Control-Allow-Headers", allowedHeaders.join(", "));
    res.setHeader("Access-Control-Allow-Credentials", "true");

    // x-proxy-host

    targetUrl = target + path;

    var headers = prepareRequestHeaders(req.headers, host);

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
      
      _this.emit("request:before", options);

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

        _this.emit("request:complete", request_data); 
      });
    });
  };
};

util.inherits(Proxy, EventEmitter);

module.exports = Proxy;
