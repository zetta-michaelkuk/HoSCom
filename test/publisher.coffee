generalContract = require('./serviceContract')

HosCom = require('../index')

services = []
instances = []

for i in [0 .. 20]
    serviceCon = JSON.parse(JSON.stringify(generalContract))
    serviceCon.name = "serviceTest#{i}"
    ins = new HosCom(serviceCon, 'al-kh.me', 'alikh', 'alikh12358')
    instances.push(ins)
    services.push(ins.connect())

Promise.all(services).then ()->
    for s in instances
        s.destroy()
