module.exports (Promise)->
  class HoSComChannelManager
    _freeChannels: []
    _requestQueue: []

    constructor: (@_channelFactory, @_settings = {})->
      @_settings.numChannels ?= 3

      _createChannel() for x in [1..@_settings.numChannels]

    getChannel: ()->
      @_allocateChannel()

    _allocateChannel: ()->
      new Promise (resolve, reject) =>
        if @_freeChannels.length
          channel = @_freeChannels.shift()
        else
          @_requestQueue.push(resolve)

    _createChannel: ()->
      @_channelFactory.get().then (channel)=>

        channel.on 'drain', ()=>
          @_channelFreed(channel)
          return

        channel.on 'close', ()=>
          @_freeChannels.splice(@_freeChannels.indexOf(channel), 1) unless @_freeChannels.indexOf(channel) is -1
          delete channel

          @_createChannel()
          return

        @_channelFreed(channel)
        return

    _channelFreed: (channel)->
      if @_requestQueue.length
        resolve = @_requestQueue.shift()
        resolve(channel)
        return

      else
        @_freeChannels.push(channel)
        return

  return ChannelManager
