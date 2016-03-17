class ReplyMessage
    reply: null

module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSConsumer extends EventEmitter
        _amqpConnection: null

        constructor: (@_HoSCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @_options = {durable: true, autoDelete: true}
            isClosed = false
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
                    ch.on "close", () =>
                        isClosed = true
                    ch.on "error", () =>
                        isClosed = true
                    @publishChannel = ch
                    @publishChannel.assertExchange("HoS", 'topic', {durable: true}).then ()=>
                        resolve()

                connectionOk.catch (err)=>
                    @isClosed = true
                    @emit('error', err)


        send: (paylaod, destination, headers, callback)->
            sendOption = {messageId: uuid.v1(), timestamp: Date.now(), headers: headers}
            destinationParts = destination.split '.'
            destService = destinationParts[0]
            sendOption.correlationId = sendOption.messageId

            key = "#{destService}"
            key += ".#{destinationParts[1]}" if destinationParts[1]

            if typeof callback is 'function'
                sendOption.replyTo = "#{@_serviceContract.name}.#{@_serviceId}"
                rep = new ReplyMessage
                rep.reply = callback
                @_HoSCom._messagesToReply[sendOption.correlationId] = rep

            return @publishChannel.publish("HoS", key, new Buffer(JSON.stringify paylaod),sendOption)

        sendReply: (message, payload)->
            sendOption = {messageId: uuid.v1(), timestamp: message.properties.timestamp, headers: message.properties.headers}
            sendOption.correlationId = message.properties.correlationId

            @publishChannel.publish("HoS", message.properties.replyTo, new Buffer(JSON.stringify paylaod),sendOption)
