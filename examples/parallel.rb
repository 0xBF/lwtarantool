#!/usr/bin/env ruby
# frozen_string_literal: true

require 'lwtarantool'

conn = LWTarantool.new(url: 'tcp://127.0.0.1:3301')

reqs = []
reqs << conn.call('box.slab.info', [])
reqs << conn.call('box.runtime.info', [])

reqs.each(&:wait)

if reqs[0].result
  p reqs[0].result
else
  p reqs[0].error
end

if reqs[1].result
  p reqs[1].result
else
  p reqs[1].error
end
