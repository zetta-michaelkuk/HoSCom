class AckMessage
    ack: null

module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSConsumer extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null

        constructor: (@_HoSCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @_options= {durable: true, autoDelete: true}
            @isClosed= false
            super()

        connect: ()->
            @_serviceContract = @_HoSCom._serviceContract
            @_serviceId = @_HoSCom._serviceId

            connectionOk = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            connectionOk.catch (err)=>
                @isClosed = true
                @emit('error', err)
                reject()

            connectionOk.then (conn)=>
                @_amqpConnection = conn
                return conn.createChannel()

            .then (ch)=>
                ch.prefetch(@_HoSCom._serviceContract.prefetch)
                ch.on "close", () =>
                    isClosed = true
                ch.on "error", () =>
                    isClosed = true

                @consumeChannel = ch
                @_CreatServiceExchange()

        _CreatServiceExchange: ()->
            if @consumeChannel
                HoSExOk = @consumeChannel.assertExchange("HoS", 'topic', {durable: true})
                HoSExOk.then ()=>
                    ok = @consumeChannel.assertExchange(@_serviceContract.name, 'topic', @_options)
                    ok.then ()=>
                        res = []
                        res.push @consumeChannel.bindExchange(@_serviceContract.name,"HoS","#{@_serviceContract.name}.#")
                        res.push @_CreateQueue "#{@_serviceContract.name}.#{@_serviceId}", "#{@_serviceContract.name}", @_serviceId
                        res.push @_CreateQueue "#{@_serviceContract.name}", "#{@_serviceContract.name}"

                        Promise.all(res)
            else
                @emit('error', 'no consume channel')
                reject()

        _CreateQueue: (queueName, bindingKey, id)->
            @consumeChannel.assertQueue(queueName, @_options)
            .then ()=>
                if id
                    bindingKey += ".#{id}"

                @consumeChannel.bindQueue(queueName, @_serviceContract.name, bindingKey).then ()=>
                    @consumeChannel.bindQueue(queueName, @_serviceContract.name, "#{bindingKey}.broadcast").then ()=>
                        pm = (msg)=>
                            @_processMessage(msg)
                        @consumeChannel.consume(queueName, pm)

        _processMessage: (msg)->
            if @_HoSCom._messagesToReply[msg.properties.correlationId]
                @consumeChannel.ack(msg)
                if typeof @_HoSCom._messagesToReply[msg.properties.correlationId].reply is 'function'
                    @_HoSCom._messagesToReply[msg.properties.correlationId].reply(JSON.parse msg.content)
                    delete @_HoSCom._messagesToReply[msg.properties.correlationId]
                return

            ack = (msg)=>
                @consumeChannel.ack(msg)

            msg.reply = (payload)=>
                ack(msg)
                if payload and msg.properties.replyTo
                    @_HoSCom.Publisher.sendReply(msg, payload)

            @emit('message', msg)
