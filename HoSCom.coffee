module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64) ->
    class HoSCom extends EventEmitter
        _amqpConnection: null
        _serviceName: null
        _serviceId: null
        _pendingMessages: []
        _options: {durable: false, autoDelete: true}

        constructor: (@_serviceName, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
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
                @consumeChannel = ch
                @_CreatServiceExchange()

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

        _CreatServiceExchange: ()->
            if @consumeChannel
                ok = @consumeChannel.assertExchange(@_serviceName, 'direct', @_options)
                ok.then ()=>
                    @_CreateQueue @consumeChannel, "#{@_serviceName}.#{@_serviceId}", @_serviceId
                    @_CreateQueue @consumeChannel, "#{@_serviceName}", ''
            else
                @emit('error', 'no consume channel')

        _CreateQueue: (ch, queueName, bindingKey)->
            ch.assertQueue(queueName, @_options)
            .then ()=>
                ch.bindQueue(queueName, @_serviceName, bindingKey)
                ch.consume queueName, (msg)=>
                    @emit('message', msg)
                    ch.ack(msg);

        SendMessage: (message, destination)->
            if @publishChannel
                destinationParts = destination.split '.'
                destService = destinationParts[0]
                destId = destinationParts[1] ? ''
                @consumeChannel.assertExchange(destService, 'direct', @_options)
                .then ()=>
                    @publishChannel.publish(destService, destId, new Buffer(JSON.stringify message))

            else
                @emit('error', 'no publish channel')


    return HoSCom
