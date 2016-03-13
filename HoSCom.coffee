module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64) ->
    HoSConsumer = require("./HoSConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64)

    class HoSCom extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null
        _pendingMessages: []
        _options: {durable: true, autoDelete: true}
        HoSConsumers: []

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
                if typeof callback is 'function'
                    callback()
                @publishChannel.on 'error', (err)=>
                    @emit('error', 'publishChannelError')

            @_amqpConnection.catch (err)=>
                @emit('error', err)

            @on 'error', (msg) =>
                if msg is "publishChannelError"
                    @publishChannel = null
                    @_amqpConnection.then (conn)=>
                        return conn.createChannel()
                    .then (ch)=>
                        @publishChannel = ch
                        console.log 'recreate channel'

            for i in [1 .. 3]
                @HoSConsumers[i] = new HoSConsumer(@, @amqpurl, @username, @password)

        SendMessage: (message, destination)->
            if @publishChannel
                destinationParts = destination.split '.'
                destService = destinationParts[0]
                key = ""
                if destinationParts[1]
                    key = "HoS.#{destService}.#{destinationParts[1]}"
                else
                    key = "HoS.#{destService}"

                @publishChannel.assertExchange("HoS", 'topic', @_options)
                .then ()=>
                    @publishChannel.publish("HoS", key, new Buffer(JSON.stringify message))

            else
                @emit('error', 'no publish channel')


    return HoSCom
