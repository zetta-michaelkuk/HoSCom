module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    HoSConsumer     = require("./HoSConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)
    HoSPublisher    = require("./HoSPublisher")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

    class HoSCom extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null
        _options: {durable: true, autoDelete: true}
        HoSConsumers: []
        _messagesToAck: {}
        _messagesToReply: {}
        Publisher: null

        constructor: (@_serviceContract, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            super()

            ServiceInfo =
                ID: crypto.randomBytes(10).toString('hex')
                CreateOn: Date.now()
                HostName: os.hostname()

            @_serviceId = URLSafeBase64.encode(new Buffer(JSON.stringify ServiceInfo))

        connect: ()->
            promises = []
            for i in [1 .. @_serviceContract.consumerNumber]
                con = new HoSConsumer(@, @amqpurl, @username, @password)
                promises.push con.connect()
                con.on 'message', (msg)=>
                    @emit("message", msg)
                @HoSConsumers[i] = con

            @Publisher = new HoSPublisher(@, @amqpurl, @username, @password)

            promises.push @Publisher.connect()

            Promise.all(promises)

        sendMessage: (payload, destination, headers, callback)->
            @Publisher.send(payload, destination, headers, callback)

        ack: (msg)->
            try
                @_messagesToAck[msg.messageId].ack(msg).then ()=>
                    delete @_messagesToAck[msg.messageId]
                    return true
            catch
                return false

    return HoSCom
