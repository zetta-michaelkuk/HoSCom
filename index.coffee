amqp            = require('amqplib')
os              = require('os')
crypto          = require('crypto')
EventEmitter    = require('events')
URLSafeBase64   = require('urlsafe-base64')
generalContract = require('./test/serviceContract')
uuid            = require('node-uuid')
Promise         = require('bluebird')

HosCom = require('./src/HoSCom')(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

service1 = JSON.parse(JSON.stringify(generalContract))
service1.name = "service1"

a = new HosCom service1, 'al-kh.me', 'alikh', 'alikh12358'
a.on 'error', (err)->
    console.log "this cool error  " +  err.toString()
a.connect()
a.on 'message', (msg)=>
    msg.reply({"sijfkjdjfhdkjh"})

module.exports = HosCom
