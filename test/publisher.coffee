generalContract = require('./serviceContract')

HosCom = require('../index')

service = JSON.parse(JSON.stringify(generalContract))
service.name = "service3"
count = 1
b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
b.connect().then ()=>
    for i in [ 1 .. 10000 ]
        b.sendMessage {u: 'kjh',i: "hjkhkj"} , "service1", {}, ()=>
            console.log count
            count = count + 1

b.on 'message', (msg)=>
    console.log msg
