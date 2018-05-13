# LWTarantool [![Build Status](https://semaphoreci.com/api/v1/0xbf/lwtarantool/branches/master/shields_badge.svg)](https://semaphoreci.com/0xbf/lwtarantool)

A Ruby client for Tarantool 1.7+.

It doesn't support all tarantool protocol features, the only function calls, but allow work with tarantool in async paradigm.

Based on official [tarantool-c](https://github.com/tarantool/tarantool-c) connector.

## Getting started

### Install

```
$ gem install lwtarantool
```

### Connect

```ruby
require 'lwtarantool'
tnt = LWTarantool.new(url: '127.0.0.1:3301')
```

### Pipelining

```ruby
reqs = []
reqs << conn.call('box.slab.info', [])
reqs << conn.call('box.runtime.info', [])

reqs.each(&:wait)

if reqs[0].result
  puts "req0 result: #{reqs[0].result.inspect}"
else
  puts "req0 error: #{reqs[0].error}"
end

if reqs[1].result
  puts "req1 result: #{reqs[1].result.inspect}"
else
  puts "req1 error: #{reqs[1].error}"
end
```

### Async requests

```ruby
slab_req = conn.call('box.slab.info', [])
runtime_req = conn.call('box.runtime.info', [])

2.times do
  req = conn.read
  case req
  when slab_req
    if req.result
      puts "slab info: #{req.result.inspect}"
    else
      puts "slab info error: #{req.error}"
    end
  when runtime_req
    if req.result
      puts "runtime info: #{req.result.inspect}"
    else
      puts "runtime info error: #{req.error}"
    end
  end
end
```

## Error handling

## Testing

This library is tested against recent Ruby versions. Check [Semaphore CI](https://semaphoreci.com/0xbf/lwtarantool) for the exact versions supported.

## Contributing

Fork the project and send pull requests.
