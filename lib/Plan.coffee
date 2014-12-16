async = require 'async'

Logger    = require './Logger'
Transform = require './Transform'

logger = new Logger 'Plan'


module.exports = class Plan
  constructor: (@stream, @targetShardCount) ->
    unless @targetShardCount >= 1
      logger.error 'Invalid desired shard count'


  execute: (kinesis, generateStream, callback) ->
    plannedTransforms = @plan()
    logger.debug {plannedTransforms}, 'Starting planned transformation execution'

    async.eachSeries plannedTransforms, (transform, done) ->
      logger.debug 'Updating stream status'
      generateStream (err, stream) ->
        return done err if err
        logger.debug {transform}, 'Executing transformation'
        transform.execute stream, kinesis, done
    , callback


  calculateEndingHashKeys: ->
    logger.debug 'Calculating target hash key borders'
    avgHashKeyRange = @stream.hashKeyRange.div @targetShardCount
    @preExistingEndingHashKeys = @stream.openShards.slice(0, -1).map (shard) ->
      shard.endingHashKey

    @targetEndingHashKeys = [1..(@targetShardCount - 1)].filter (num) ->
      num > 0
    .map (num) =>
      @stream.startingHashKey.add(avgHashKeyRange.mul(num))


  plan: ->
    logger.debug 'Generating transformation plan'
    @calculateEndingHashKeys()
    @planSplits()
    @planMerges()
    @splits.concat @merges


  planSplits: ->
    logger.debug 'Generating split transformation plan'
    @splits = @targetEndingHashKeys.filter (key) =>
      key.lt(@stream.endingHashKey)
    .map (borderHashKey) =>
      new Transform.Split borderHashKey

    logger.debug {@splits}, 'Generated split transformation plan'


  planMerges: ->
    logger.debug 'Generating merge transformation plan'
    @merges = @stream.openShards.filter (shard) =>
      return if shard.endingHashKey in @targetEndingHashKeys
      return if shard.endingHashKey is @stream.endingHashKey
      return true
    .map (shardToMerge) ->
      new Transform.Merge shardToMerge.endingHashKey, shardToMerge.endingHashKey.add(1)

    logger.debug {@merges}, 'Generated merge transformation plan'
