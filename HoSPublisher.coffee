module.exports = (Promise, amqp, uuid) ->
  HoSChannelManager = require('./HoSChannelManager')(Promise)

  class HoSPublisher

    constructor: (@_hosCom, @amqpurl, @username, @password)->


    Connect: ()->
      amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}").then (conn)=>
        @_amqpConnection = conn
        @_hosChannel = new HoSChannelManager(conn)

    send: (payload, to, headers)->
      new Promise (resolve, reject)=>
        options =
          headers: headers
          correlationId: uuid.v1()
          replyTo: "#{@_hosCom._serviceContract.name}.#{@_hosCom._serviceId}"

        parts = to.split '.'

        routingKey = parts[0]
        routingKey += ".#{parts[1]}" if parts[1]

      @_hosChannel.get().then (ch)=>
        @_hosCom._pendingMessages[options.correlationId] = {resolve: resolve, reject: reject}
        ch.publish('HoS', routingKey, payload, options)
