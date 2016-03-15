module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid) ->
    HoSConsumer = require("./HoSConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid)

    class HoSCom extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null
        _pendingMessages: []
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
            @_amqpConnection = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            @_amqpConnection.then (conn)=>
                return conn.createChannel()
            .then (ch)=>
                @publishChannel = ch
                @publishChannel.assertExchange("HoS", 'topic', @_options)
                if typeof callback is 'function'
                    callback()
                @publishChannel.on 'error', (err)=>
                    @emit('error', 'publishChannelError')

            @_amqpConnection.catch (err)=>
                @emit('error', err)

            for i in [1 .. @_serviceContract.consumerNumber]
                con = new HoSConsumer(@, @amqpurl, @username, @password)
                con.on 'message', (msg)=>
                    @emit("message", msg)
                @HoSConsumers[i] = con


        SendMessage: (message, destination)->
            if @publishChannel
                destinationParts = destination.split '.'
                destService = destinationParts[0]
                key = "#{destService}"
                if destinationParts[1]
                    key += ".#{destinationParts[1]}"

                @publishChannel.publish("HoS", key, new Buffer(JSON.stringify message),{correlationId: uuid.v1()})

            else
                @emit('error', 'no publish channel')

        ack: (msg)->
            try
                @_messagesToAck[msg.properties.correlationId].ack(msg)
                delete @_messagesToAck[msg.properties.correlationId]
                return true
            catch
                return false

    return HoSCom
