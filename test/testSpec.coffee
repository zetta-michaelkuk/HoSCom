generalContract = require('./serviceContract')
HosCom = require('../index')

describe "Create service", ()->
    beforeEach ()->
        @service = JSON.parse(JSON.stringify(generalContract))
        @service.name = "serviceTest"
        @b = new HosCom @service, 'al-kh.me', 'alikh', 'alikh12358'

    afterEach ()->
        if @b
            @b.destroy()

    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @b.connect().then ()->
            done()

    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @b.connect().then ()->
            done()

    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @b.connect().then ()->
            done()


    it "and it should get all the promisses to connect into rabbitMQ", (done)->
        @b.connect().then ()->
            done()
