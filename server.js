var express = require("express");
var path    = require("path");
var app     = express();

app.listen(3000);
app.get('/', function(req, res){
    console.log("Listening to Port 3000");
    res.sendFile(path.join(__dirname, './','index.html')); //Pfad ggf. anpassen
});