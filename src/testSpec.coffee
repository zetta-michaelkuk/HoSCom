generalContract = require('./serviceContract')
HosCom = require('../index')

describe "Create service", ()->
    b = null

    afterEach ()->
        if b
            b.destroy()

    it "and it should get all the promisses to connect into rabbitMQ", (done)=>
        service = JSON.parse(JSON.stringify(generalContract))
        service.name = "serviceTest"
        b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
        b.connect().then ()=>
            done()

    it "and it should get all the promisses to connect into rabbitMQ", (done)=>
        service = JSON.parse(JSON.stringify(generalContract))
        service.name = "serviceTest"
        b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
        b.connect().then ()=>
            done()

    it "and it should get all the promisses to connect into rabbitMQ", (done)=>
        service = JSON.parse(JSON.stringify(generalContract))
        service.name = "serviceTest"
        b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
        b.connect().then ()=>
            done()


    it "and it should get all the promisses to connect into rabbitMQ", (done)=>
        service = JSON.parse(JSON.stringify(generalContract))
        service.name = "serviceTest"
        b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
        b.connect().then ()=>
            done()






describe "A spec (with setup and tear-down)", ()=>
  foo = 0

  beforeEach ()->
    foo = 0
    foo += 1

  afterEach ()->
    foo = 0

  it "is just a function, so it can contain any code", ()->
    expect(foo).toEqual(1)

  it "can have more than one expectation", ()->
    expect(foo).toEqual(1)
    expect(true).toEqual(true)
