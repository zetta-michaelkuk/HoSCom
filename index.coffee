amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')

HosCom = require('./HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64)



a = new HosCom 'myService', 'al-kh.me', 'alikh', 'alikh12358'
a.on 'error', (err)->
    console.log "this cool error  " +  err.toString()
a.Connect ()->
    b = new HosCom 'theirService', 'al-kh.me', 'alikh', 'alikh12358'
    b.Connect () ->
        for i in [ 1 .. 2 ]
            b.SendMessage {u: 'kjh',i: "hjkhkj"} , "myService123"

module.exports = HosCom
