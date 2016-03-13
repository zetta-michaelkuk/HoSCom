module.exports =
    class HoSMsgPool
        _sentStack = {}
        _receivedStack = {}

        constructor: (@_HoSCom) ->
            console.log "connnnn"

        pushToSent: (msg) ->
            _sentStack[msg.id] = msg

        pushToReceived: (msg) ->
            _receivedStack[msg.id] = msg

            sentMsg = _sentStack[msg.id]

            if sentMsg
                delete _sentStack[msg.id]
                sentMsg.callback()
