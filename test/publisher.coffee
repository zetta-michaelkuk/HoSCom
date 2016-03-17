generalContract = require('./serviceContract')
HosCom          = require('../index')

amqpurl     = process.env.AMQP_URL ? "al-kh.me"
username    = process.env.AMQP_USERNAME ? "alikh"
password    = process.env.AMQP_PASSWORD ? "alikh12358"


@serviceCon = JSON.parse(JSON.stringify(generalContract))
@serviceCon.name = "serviceTest"
@service1 = new HosCom @serviceCon, amqpurl, username, password

@serviceCon2 = JSON.parse(JSON.stringify(generalContract))
@serviceCon2.name = "service2Test"
@service2 = new HosCom @serviceCon2, amqpurl, username, password

@service1.connect().then ()=>
    @service2.connect().then ()=>
        @service2.sendMessage {foo: "bar"} , @serviceCon.name, {}, (msg)->
            console.log msg


@service1.on 'message', (msg)=>
    console.log "-----------"
    msg.reply({foo: "notbar"})
