var req = require('request');
var jsdom = require("jsdom").jsdom;

var readability = require("readability-node");
var Readability = readability.Readability;

var uri = process.argv[2];

req.get(uri, function (error, response, body) {

    var doc = jsdom(body, {
      features: {
        FetchExternalResources: false,
        ProcessExternalResources: false
      }
    });
    
    var article = new Readability({}, doc).parse();

    var json = {
      'title': article.title,
      'excerpt': article.excerpt,
      'author': article.byline,
      'content': article.content,
      'length': article.length,
      'byline': article.byline,
      'uri': article.uri
    }

    console.log(JSON.stringify(json));
});