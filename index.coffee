amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')
generalContract = require('./serviceContract')

HosCom = require('./HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64)

service1 = JSON.parse(JSON.stringify(generalContract))
service1.name = "service1"

service2 = JSON.parse(JSON.stringify(generalContract))
service2.name = "service2"

a = new HosCom service1, 'al-kh.me', 'alikh', 'alikh12358'
a.on 'error', (err)->
    console.log "this cool error  " +  err.toString()
a.Connect ()->
    b = new HosCom service2, 'al-kh.me', 'alikh', 'alikh12358'
    b.Connect () ->
        for i in [ 1 .. 10 ]
            b.SendMessage {u: 'kjh',i: "hjkhkj"} , service1.name

module.exports = HosCom
