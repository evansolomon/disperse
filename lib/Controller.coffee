Kinesis = require './Kinesis'
Logger  = require './Logger'
Plan    = require './Plan'
Shard   = require './Shard'
Stream  = require './Stream'

logger = new Logger 'Controller'


module.exports = class Controller
  constructor: (@streamName, awsConfig) ->
    @kinesis = new Kinesis streamName, awsConfig


  updateStream: (callback) ->
    logger.debug 'Updating stream status'
    @kinesis.refresh (err) =>
      if err
        logger.error err
        return callback err

      @stream = new Stream @streamName, @kinesis.shards.map (shard) ->
        logger.debug {shard, @streamName}, 'Adding shard to stream'
        new Shard shard.ShardId, shard.HashKeyRange, shard.SequenceNumberRange

      callback()


  resizeTo: (desiredShards, callback) ->
    logger.info 'Generating resize plan targeting %d shards', desiredShards
    plan = new Plan @stream, desiredShards

    generateStream = (done) =>
      @updateStream (err) =>
        return done err if err
        done null, @stream

    plan.execute @kinesis, generateStream, (err) =>
      return callback err if err
      # Wait for last update to apply
      @kinesis.onActiveStream =>
        logger.info 'Finished resize'
        callback arguments...


  upsize: (margin = 1, callback) ->
    logger.info 'Upsizing by %d shards', margin
    @updateStream (err) =>
      return callback err if err
      @resizeTo (@stream.openShards.length + margin), callback


  downsize: (margin = 1, callback) ->
    logger.info 'Downsizing by %d shards', margin
    @updateStream (err) =>
      return callback err if err
      @resizeTo (@stream.openShards.length - margin), callback


  resize: (desiredShards, callback) ->
    @updateStream (err) =>
      return callback err if err
      @resizeTo desiredShards, callback
