module.exports = class Stream
  constructor: (@name, shards) ->
    # Make sure shards are sorted
    # Hash key ranges are unique and contiguous
    @openShards = shards
      .filter (shard) -> shard.isOpen()
      .sort (a, b) -> a.startingHashKey - b.startingHashKey

    {@startingHashKey, @endingHashKey} = @openShards.slice(1).reduce (memo, shard) ->
      if shard.startingHashKey.lt memo.startingHashKey
        memo.startingHashKey = shard.startingHashKey

      if shard.endingHashKey.gt memo.endingHashKey
        memo.endingHashKey = shard.endingHashKey

      memo
    , {startingHashKey: @openShards[0].startingHashKey, endingHashKey: @openShards[0].endingHashKey}

    @hashKeyRange = @endingHashKey.sub @startingHashKey
    @openShardCount = @openShards.length


  findShardByHashKey: (hashKey) ->
    @openShards.filter (shard) ->
      shard.contains hashKey
    .pop()
