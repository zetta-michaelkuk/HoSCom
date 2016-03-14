amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')
generalContract = require('./serviceContract')
uuid            = require('node-uuid');

HosCom = require('./HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid)

service = JSON.parse(JSON.stringify(generalContract))
service.name = "service3"

b = new HosCom service, 'al-kh.me', 'alikh', 'alikh12358'
b.Connect () ->
    for i in [ 1 .. 10000 ]
        b.SendMessage {u: 'kjh',i: "hjkhkj"} , "service1"

module.exports = HosCom
