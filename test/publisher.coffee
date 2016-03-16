generalContract = require('./serviceContract')

HosCom = require('../index')

service = JSON.parse(JSON.stringify(generalContract))
service.name = "service3"
count = 1
b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
b.connect().then ()=>
  b.destroy()

b.on 'message', (msg)=>
    console.log msg
