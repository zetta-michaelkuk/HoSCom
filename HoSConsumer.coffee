class AckMessage
    ack: null

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
                ch.prefetch(@_HoSCom._serviceContract.prefetch)
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
                    ok = @consumeChannel.assertExchange(@_serviceContract.name, 'topic', @_options)
                    ok.then ()=>
                        @consumeChannel.bindExchange(@_serviceContract.name,"HoS","#{@_serviceContract.name}.#")
                        @_CreateQueue "#{@_serviceContract.name}.#{@_serviceId}", "#{@_serviceContract.name}", @_serviceId
                        @_CreateQueue "#{@_serviceContract.name}", "#{@_serviceContract.name}"
            else
                @emit('error', 'no consume channel')

        _CreateQueue: (queueName, bindingKey, id)->
            @consumeChannel.assertQueue(queueName, @_options)
            .then ()=>
                if id
                    @consumeChannel.bindQueue(queueName, @_serviceContract.name, "#{bindingKey}.broadcast")
                    bindingKey += ".#{id}"

                @consumeChannel.bindQueue(queueName, @_serviceContract.name, bindingKey)
                @consumeChannel.consume queueName, (msg)=> @_processMessage(msg)

        _processMessage: (msg)->
            ack = (msg)=>
                @consumeChannel.ack(msg);

            ackMessage = new AckMessage
            ackMessage.ack = ack
            @_HoSCom._messagesToAck[msg.properties.correlationId] = ackMessage
            @emit('message', msg)
