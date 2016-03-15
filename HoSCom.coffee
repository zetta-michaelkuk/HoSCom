module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    HoSConsumer = require("./HoSConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid)
    HoSPublisher = require("./HoSPublisher")(Promise, amqp, uuid)

    class HoSCom extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null
        _pendingMessages: {}
        _options: {durable: true, autoDelete: true}
        HoSConsumers: []
        _messagesToAck: {}

        constructor: (@_serviceContract, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            super()

            ServiceInfo =
                CreateOn: Date.now()
                HostName: os.hostname()
                ID: crypto.randomBytes(10).toString('hex')

            @_serviceId = URLSafeBase64.encode(new Buffer(JSON.stringify ServiceInfo))


        Connect: (callback)->
            @_hosPublisher = new HoSPublisher(@, @amqpurl, @username, @password)

            @_hosPublisher.Connect().then ()=>
                if typeof callback is 'function'
                    callback()

                for i in [1 .. @_serviceContract.consumerNumber]
                    con = new HoSConsumer(@, @amqpurl, @username, @password)
                    con.on 'message', (msg)=>
                        @emit("message", msg)
                    @HoSConsumers[i] = con


        SendMessage: (message, destination, headers)->

            @_hosPublisher.send(message, destination, headers)

        ack: (msg)->
            try
                @_messagesToAck[msg.properties.correlationId].ack(msg)
                delete @_messagesToAck[msg.properties.correlationId]
                return true
            catch
                return false

    return HoSCom
