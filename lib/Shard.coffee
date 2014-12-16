bignum = require 'bignum'


module.exports = class Shard
  constructor: (@id, hashKeyRange, @sequenceNumberRange) ->
    @startingHashKey = bignum hashKeyRange.StartingHashKey
    @endingHashKey = bignum hashKeyRange.EndingHashKey


  contains: (hashKey) ->
    @startingHashKey.le(hashKey) and @endingHashKey.ge(hashKey)


  isOpen: ->
    ! @sequenceNumberRange.EndingSequenceNumber
