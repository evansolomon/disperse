# Disperse

Resize Kinesis streams and automatically maintain evenly-sized shards.


## Why?

[Kinesis](https://aws.amazon.com/kinesis/) is great, but its API for scaling streams is pretty bad unless you either always want to double or halve your stream capacity (you don't) or you are fine with massively different shard sizes across your stream (you're not).  Disperse takes a target stream capacity (e.g. 4 shards) or change to your current stream capacity (e.g. add 2 shards) and resizes things so that you come out with the number of shards you want that are all the same size.


## Usage

Example of adding 2 shards to a stream called "some-click-stream" located in us-east-1.

```
disperse --stream some-click-stream --upsize 2 --aws.region us-east-1
```

Help output.

```
$ disperse help
Usage:
  --stream       [stream name]
  --aws.[option] [option value]
  --upsize       [shards to add]
  --downsize     [shards to remove]
  --resize       [target shards]

Only use one of --upsize, --downsize, or --resize
```
