class AckMessage
    ack: null

module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSConsumer extends EventEmitter
        _amqpConnection: null
        _serviceContract: null
        _serviceId: null
        _options: {durable: true, autoDelete: true}
        isClosed: false

        constructor: (@_HoSCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            super()

        connect: ()->
            new Promise (resolve, reject)=>
                @_serviceContract = @_HoSCom._serviceContract
                @_serviceId = @_HoSCom._serviceId

                connectionOk = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

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
                    @_CreatServiceExchange(resolve, reject).then ()->
                        resolve()

                connectionOk.catch (err)=>
                    @isClosed = true
                    @emit('error', err)
                    reject()

        _CreatServiceExchange: ()->
            if @consumeChannel
                HoSExOk = @consumeChannel.assertExchange("HoS", 'topic', @_options)
                HoSExOk.then ()=>
                    ok = @consumeChannel.assertExchange(@_serviceContract.name, 'topic', @_options)
                    ok.then ()=>
                        res = []
                        @consumeChannel.bindExchange(@_serviceContract.name,"HoS","#{@_serviceContract.name}.#")
                        res.push @_CreateQueue "#{@_serviceContract.name}.#{@_serviceId}", "#{@_serviceContract.name}", @_serviceId
                        res.push @_CreateQueue "#{@_serviceContract.name}", "#{@_serviceContract.name}"

                        Promise.all(res)

        _CreateQueue: (queueName, bindingKey, id)->
            @consumeChannel.assertQueue(queueName, @_options)
            .then ()=>
                promisses = []
                if id
                    promisses.push @consumeChannel.bindQueue(queueName, @_serviceContract.name, "#{bindingKey}.broadcast")
                    bindingKey += ".#{id}"

                promisses.push @consumeChannel.bindQueue(queueName, @_serviceContract.name, bindingKey)
                promisses.push @consumeChannel.consume queueName, (msg)=> @_processMessage(msg).then ()=>

                Promise.all promisses

        _processMessage: (msg)->
            if @_HoSCom._messagesToReply[msg.properties.correlationId]
                @consumeChannel.ack(msg)
                if typeof @_HoSCom._messagesToReply[msg.properties.correlationId].reply is 'function'
                    @_HoSCom._messagesToReply[msg.properties.correlationId].reply()
                    delete @_HoSCom._messagesToReply[msg.properties.correlationId]
                return

            ack = (msg)=>
                @consumeChannel.ack(msg)

            ackMessage = new AckMessage
            ackMessage.ack = ack
            @_HoSCom._messagesToAck[msg.messageId] = ackMessage

            if msg.properties.replyTo
                msg.reply = (payload)=>
                    ack(msg)
                    if payload
                        @_HoSCom.Publisher.sendReply(msg, payload)

            @emit('message', msg)
