generalContract = require('./serviceContract')
HosCom = require('../index')
Promise = require('bluebird')

describe "Create service", ()->
    beforeEach ()->

    afterEach ()->


    it "and it should create 10 instances of hos and destroy them", (done)->
        services = []
        instances = []

        for i in [0 .. 10]
            serviceCon = JSON.parse(JSON.stringify(generalContract))
            serviceCon.name = "serviceTest#{i}"
            ins = new HosCom(serviceCon, 'al-kh.me', 'alikh', 'alikh12358')
            instances.push(ins)
            services.push(ins.connect())

        Promise.all(services).then ()->
            for s in instances
                s.destroy()
            done()


    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.name = "serviceTest"
        @service1 = new HosCom @serviceCon, 'al-kh.me', 'alikh', 'alikh12358'

        @serviceCon2 = JSON.parse(JSON.stringify(generalContract))
        @serviceCon2.name = "service2Test"
        @service2 = new HosCom @serviceCon2, 'al-kh.me', 'alikh', 'alikh12358'

        @service1.connect().then ()=>
            @service2.connect().then ()=>
                for i in [ 1 .. 5 ]
                    @service2.sendMessage {u: 'kjh',i: "hjkhkj"} , @serviceCon.name, {}

        count = 0
        @service1.on 'message', (msg)=>
            msg.reply()
            count = count + 1
            if count is 5
                @service2.destroy()
                @service1.destroy()
                done()
