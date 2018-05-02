#!/usr/bin/env ruby

require 'lwtarantool'

conn = LWTarantool.new(url: 'tcp://127.0.0.1:3301')

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
