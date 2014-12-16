AWS   = require 'aws-sdk'
async = require 'async'

Logger = require './Logger'

logger = new Logger 'Kinesis'


module.exports = class Kinesis
  @states: {'ACTIVE', 'DELETING'}

  constructor: (name, awsConfig = {}) ->
    awsConfig.params ||= {}
    awsConfig.params.StreamName = name
    @client = new AWS.Kinesis awsConfig


  refresh: (callback) ->
    logger.debug 'Refreshing Kinesis stream status'
    @listShards (err, shards) =>
      return callback err if err
      @shards = shards
      callback()


  listShards: (callback) ->
    shards = []

    @onActiveStream =>
      foundAllShards = false
      lastShardId = undefined

      async.doUntil (done) =>
        @client.describeStream {ExclusiveStartShardId: lastShardId}, (err, data) ->
          return done err if err

          shards = shards.concat data.StreamDescription.Shards
          lastShardId = data.StreamDescription.Shards.slice(-1).ShardId
          foundAllShards = ! data.HashMoreShards

          done()
      , ->
        foundAllShards
      , (err) ->
        return callback err if err
        logger.debug {shards}, 'Updated Kinesis stream shards'
        callback null, shards


  onActiveStream: (callback) ->
    logger.debug 'Waiting for stream to be active'
    isActive = false

    async.doUntil (done) =>
      @client.describeStream {}, (err, data) ->
        return done err if err

        streamStatus = data.StreamDescription.StreamStatus
        return done new Error('Stream is deleted') if streamStatus is Kinesis.states.DELETING

        isActive = streamStatus is Kinesis.states.ACTIVE
        return setTimeout done, 1000 unless isActive
        done()

    , ->
      isActive
    , callback
