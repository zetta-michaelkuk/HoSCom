module.exports = (Promise, uuid)->
  class HoSPublisher

    constructor: (@_hosCom, @_hosChannel)->

    # TODO: Test
    send: (to, headers, payload)->
      new Promise (resolve, reject)=>
        options =
          headers: headers
          correlationId: uuid.v1()
          replyTo: "#{@_hosCom._serviceContract.name}.#{@_hosCom._serviceId}"

        parts = to.split '.'

        routingKey = parts[0]
        routingKey += ".#{parts[1]}" if parts[1]

      @_hosChannel.get().then (ch)=>
        @_hosCom._pendingMessages.push({resolve: resolve, reject: reject})
        ch.publish('HoS', routingKey, payload, options)
