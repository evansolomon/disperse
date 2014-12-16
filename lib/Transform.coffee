Logger = require './Logger'

logger = new Logger 'Transform'


module.exports = class Transform
  execute: ->
    throw new Error 'execute() must be implemented'


  run: (kinesis, method, params, callback) ->
    logger.info {method, params}, 'Running transform'
    kinesis.client[method].call kinesis.client, params, callback


module.exports.Merge = class Transform.Merge extends Transform
  constructor: (@hashKeyTarget, @adjacentHashKeyTarget) ->

  execute: (stream, kinesis, callback) ->
    shards = [@hashKeyTarget, @adjacentHashKeyTarget].map (hashKey) ->
      stream.findShardByHashKey hashKey

    logger.debug {shards, @hashKeyTarget, @adjacentHashKeyTarget}, 'Executing merge transform'

    params = {
      StreamName: stream.name
      ShardToMerge: shards[0].id
      AdjacentShardToMerge: shards[1].id
    }

    @run kinesis, 'mergeShards', params, callback


module.exports.Split = class Transform.Split extends Transform
  constructor: (@hashKeyTarget) ->

  execute: (stream, kinesis, callback) ->
    shard = stream.findShardByHashKey @hashKeyTarget

    logger.debug {shard, @hashKeyTarget}, 'Executing split transform'

    params = {
      StreamName: stream.name
      ShardToSplit: shard.id
      NewStartingHashKey: @hashKeyTarget.toString()
    }

    @run kinesis, 'splitShard', params, callback
