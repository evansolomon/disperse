# Disperse

Resize Kinesis stream and automatically maintain evenly-sized shards.


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
