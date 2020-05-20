var express = require('express');
var app = express();

app.use(express.json({limit : "50mb"}));
app.use(express.urlencoded( {limit : "50mb",extended : false } ));

var http = require('http').Server(app),
    io = require('socket.io')(http),
    osc = require('node-osc'),
    bodyParser = require('body-parser');

app.get('/', (req, res) => res.send("hi")); 
app.get("/chat",(req,res) => res.sendFile('/Users/doylekim/wserver/index.html'));
app.get("/views",(req,res) => res.sendFile('/Users/doylekim/wserver/views.html'));

app.post("/ph",(req,res) =>{
    var photo = req.body;
    return res.json("true");
});

io.on('connection', (socket) => {
    socket.on('send_message', (msg) =>{
        io.emit('receive_message', msg);
    });

    socket.on('SEND', (msg) =>{
        console.log(msg);
        io.emit('REC', msg);
    });

    socket.on('SEND_ITEM', (msg) =>{
        console.log(msg);
        io.emit('REC_ITEM', msg);
    });
});


var nameRoom = io.of('/name').on('connection', (socket) => {
    socket.on('nameChat', (data) =>{

        // data
        // {
        //     name:"",
        //     room:"",
        //     msg:""
        // }

        console.log(`DATA : ${data} `);
        var name = socket.name = data.name;
        var room = socket.room = data.room;
        console.log(`NAME : ${name}`);
        console.log(`ROOM : ${room}`);

        socket.join(room);
        nameRoom.to(room).emit("nameChatRoom", data.msg)
    });
});

var oscServer = new osc.Server(44100, '0.0.0.0');

oscServer.on("message", (msg, rinfo) => {
    console.log(msg[1]);
    var data;
    if(msg.length > 2){
        data = msg[2];       
    }
    else{
        data = msg[0].split('push')[1]+0;
    }
    io.emit('receive_message', {
        "name":"James",
        "message":data
    });
    console.log(`MSG : ${msg}`);
    return;
});

http.listen(8808, () => console.log('listening on :8808'));
