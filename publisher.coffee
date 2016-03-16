amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')
generalContract = require('./serviceContract')
uuid            = require('node-uuid')
Promise         = require('bluebird')

HosCom = require('./HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

service = JSON.parse(JSON.stringify(generalContract))
service.name = "service3"
count = 1
b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
b.connect().then ()=>
    for i in [ 1 .. 10000 ]
        b.sendMessage {u: 'kjh',i: "hjkhkj"} , "service1", {}, ()=>
            console.log count
            count = count+1

b.on 'message', (msg)=>
    console.log msg

module.exports = HosCom
