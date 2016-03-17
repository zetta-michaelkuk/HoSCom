generalContract = require('./serviceContract')
HosCom = require('../index')
Promise = require('bluebird')

amqpurl     = process.env.AMQP_URL ? "al-kh.me"
username    = process.env.AMQP_USERNAME ? "alikh"
password    = process.env.AMQP_PASSWORD ? "alikh12358"

describe "Create service", ()->
    it "and it should create 10 instances of hos and destroy them", (done)->
        services = []
        instances = []

        for i in [0 .. 10]
            serviceCon = JSON.parse(JSON.stringify(generalContract))
            serviceCon.name = "serviceTest#{i}"
            ins = new HosCom(serviceCon, amqpurl, username, password)
            instances.push(ins)
            services.push(ins.connect())

        Promise.all(services).then ()->
            for s in instances
                s.destroy()
            done()


    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "serviceTest"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service2Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                for i in [ 1 .. 10 ]
                    @service2.sendMessage {foo: "bar"} , @serviceCon.name, {}

        count = 0
        @service1.on 'message', (msg)=>
            msg.reply()
            count = count + 1
            if count is 5
                @service2.destroy()
                @service1.destroy()
                done()


    it "and it sends a message and get the reply", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "serviceTest"
        @service1 = new HosCom @serviceCon, amqpurl, username, password

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service2Test"
        @service2 = new HosCom @serviceCon2, amqpurl, username, password

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                @service2.sendMessage {foo: "bar"} , @serviceCon.name, {}, (replyPayload)=>
                    if replyPayload.foo is 'notbar'
                        @service2.destroy()
                        @service1.destroy()
                        done()

        @service1.on 'message', (msg)=>
            msg.reply({foo: "notbar"})
