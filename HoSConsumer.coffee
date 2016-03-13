module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64) ->
    class HoSConsumer extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null
        _options: {durable: true, autoDelete: true}
        isClosed: false

        constructor: (@_HoSCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            super()

            @_serviceContract = @_HoSCom._serviceContract
            @_serviceId = @_HoSCom._serviceId

            @Connect()

        Connect: ()->
            @_amqpConnection = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            @_amqpConnection.then (conn)=>
                return conn.createChannel()

            .then (ch)=>
                ch.prefetch(1)
                ch.on "close", () =>
                    isClosed = true
                ch.on "error", () =>
                    isClosed = true

                @consumeChannel = ch
                @_CreatServiceExchange()

            @_amqpConnection.catch (err)=>
                @isClosed = true
                @emit('error', err)

        _CreatServiceExchange: ()->
            if @consumeChannel
                HoSExOk = @consumeChannel.assertExchange("HoS", 'topic', @_options)
                HoSExOk.then ()=>
                    ok = @consumeChannel.assertExchange(@_serviceContract.name, 'direct', @_options)
                    ok.then ()=>
                        @consumeChannel.bindExchange(@_serviceContract.name,"HoS","HoS.#{@_serviceContract.name}.#")
                        @_CreateQueue "#{@_serviceContract.name}.#{@_serviceId}", "HoS.#{@_serviceContract.name}.#{@_serviceId}"
                        @_CreateQueue "#{@_serviceContract.name}", "HoS.#{@_serviceContract.name}"
            else
                @emit('error', 'no consume channel')

        _CreateQueue: (queueName, bindingKey)->
            @consumeChannel.assertQueue(queueName, @_options)
            .then ()=>
                @consumeChannel.bindQueue(queueName, @_serviceContract.name, bindingKey)
                @consumeChannel.consume queueName, (msg)=>
                    @_processMessage(msg)

        _processMessage: (msg)->
            @emit('message', msg)
            console.log msg
            doSomething = ()=>
                @consumeChannel.ack(msg);
            setTimeout(doSomething, 3000);
