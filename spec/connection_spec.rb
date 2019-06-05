# frozen_string_literal: true

require_relative 'spec_helper'

describe 'LWTarantool::Connection' do
  before(:each) do
    start_tarantool '
      require "fiber";
      function test1() return {1, 2, 3}; end
      function test2() return 1, 2, 3; end
      function test3(p1, p2) return p1, p2; end
    '
  end

  after(:each) do
    stop_tarantool
  end

  let(:conn) do
    LWTarantool.new(url: '127.0.0.1:3301')
  end

  context '#initialize' do
    it 'accept url' do
      expect { LWTarantool.new(url: '127.0.0.1:3301') }.not_to raise_error
    end

    it 'require string url' do
      expect { LWTarantool.new({}) }.to raise_error(ArgumentError, /url must be a String/)
      expect { LWTarantool.new(url: 123) }.to raise_error(ArgumentError, /url must be a String/)
    end

    it 'use url' do
      expect { LWTarantool.new(url: '127.0.0.1:3302') }.to raise_error(LWTarantool::SystemError, /Connection refused/)
      expect { LWTarantool.new(url: '127.0.0.1:3301') }.not_to raise_error
    end

    it 'raise when tarantool host not resolved' do
      expect { LWTarantool.new(url: 'aaaa.aa') }.to raise_error(LWTarantool::ResolvError)
    end

    it 'raise when tarantool not started' do
      expect { LWTarantool.new(url: '127.0.0.1:3302') }.to raise_error(LWTarantool::SystemError, /Connection refused/)
    end

    context 'timeout' do
      # FIXME: 8.8.8.8 is well-known IP address with blackholed ports, but there are no any garantees

      it 'raise when connect timeout' do
        expect { LWTarantool.new(url: '8.8.8.8:3301', connect_timeout: 0.01) }.to raise_error(LWTarantool::TimeoutError, /operation timeout/)
      end

      it 'use connect_timeout' do
        [0.2, 0.5].each do |timeout|
          time = Time.now

          begin
            LWTarantool.new(url: '8.8.8.8:3301', connect_timeout: timeout)
          rescue LWTarantool::TimeoutError
          end

          expect(Time.now - time).to be_within(0.1).of(timeout)
        end
      end

      it 'use open_timeout' do
        [0.2, 0.5].each do |timeout|
          time = Time.now

          begin
            LWTarantool.new(url: '8.8.8.8:3301', open_timeout: timeout)
          rescue LWTarantool::TimeoutError
          end

          expect(Time.now - time).to be_within(0.1).of(timeout)
        end
      end
    end

    it 'create mutex' do
      conn = LWTarantool.new(url: '127.0.0.1:3301')
      expect(conn.instance_eval { @mutex }).to be_a Mutex
    end
  end

  context '#call' do
    it 'returns Request' do
      expect(conn.call('test1', [])).to be_a(LWTarantool::Request)
    end

    it 'use func name' do
      conn.call('test1', ['aaa'])
      expect(conn.read.result).to eq [[1, 2, 3]]
    end

    it 'use args' do
      conn.call('test3', %w[aaa bbb])
      expect(conn.read.result).to eq %w[aaa bbb]
    end

    it 'thread-safe' do
      expect(conn.instance_eval { @mutex }).to receive(:synchronize)
      conn.call('test1', [])
    end

    it 'reconnect if connection lost' do
      conn
      stop_tarantool
      start_tarantool
      expect { conn.call('test1', []) }.not_to raise_exception
      expect { conn.call('test1', []) }.not_to raise_exception
    end

    it 'raise if reconnect fail' do
      conn
      stop_tarantool
      # tarantool-c doesn't return error on first call & flush after connection fail
      expect { conn.call('test1', []) }.not_to raise_exception
      expect { conn.call('test1', []) }.to raise_exception(LWTarantool::SystemError)
    end

    it 'mark all active requests as ready' do
      req1 = conn.call('test1', [])
      req2 = conn.call('test1', [])
      stop_tarantool
      # tarantool-c doesn't return error on first call & flush after connection fail
      conn.call('test1', []) rescue nil
      conn.call('test1', []) rescue nil
      expect(req1.ready?).to eq true
      expect(req2.ready?).to eq true
      expect(req1.error).to match(/canceled/)
      expect(req2.error).to match(/canceled/)
    end

    it 'raise TooLargeRequestError if request > send buffer' do
      conn = LWTarantool.new(url: '127.0.0.1:3301', send_buf_size: 20_021)
      expect { conn.call('test', ['x' * 19_999]) }.not_to raise_error
      expect { conn.call('test', ['x' * 20_000]) }.to raise_error(LWTarantool::TooLargeRequestError)
    end
  end

  context '#read' do
    it 'returns Request' do
      conn.call('test1', [])
      expect(conn.read).to be_a(LWTarantool::Request)
    end

    it 'returns same Request as appropriate #call' do
      req1 = conn.call('test1', [])
      req2 = conn.read
      expect(req1).to eq(req2)
    end

    it 'update Request status' do
      req = conn.call('test1', [])
      expect(req.ready?).to eq(false)
      conn.read
      expect(req.ready?).to eq(true)
    end

    it 'thread-safe' do
      conn.call('test1', [])
      expect(conn.instance_eval { @mutex }).to receive(:synchronize)
      conn.read
    end

    it 'raise if connection lost' do
      conn.call('fiber.sleep', [3600])
      stop_tarantool
      expect { conn.read }.to raise_exception(LWTarantool::SystemError)
    end

    it 'mark all unfinished requests as failed if connection failed' do
      req1 = conn.call('fiber.sleep', [60])
      req2 = conn.call('fiber.sleep', [60])
      stop_tarantool
      conn.read rescue nil
      expect(req1.ready?).to be true
      expect(req2.ready?).to be true
      expect(req1.error).to match(/canceled/)
      expect(req2.error).to match(/canceled/)
      expect(req1.result).to be_nil
      expect(req2.result).to be_nil
    end
  end

  context '#connected?' do
    it 'returns true when connected' do
      expect(conn.connected?).to eq true
    end

    it 'returns false when disconnected' do
      conn.disconnect
      expect(conn.connected?).to eq false
    end
  end

  context '#disconnect' do
    it 'close connection' do
      conn.disconnect
      expect(conn.connected?).to be false
    end

    it 'mark all requests as failed' do
      req1 = conn.call('test1', [])
      req2 = conn.call('test1', [])
      conn.disconnect
      expect(req1.ready?).to be true
      expect(req2.ready?).to be true
      expect(req1.error).to match(/canceled/)
      expect(req2.error).to match(/canceled/)
      expect(req1.result).to be_nil
      expect(req2.result).to be_nil
    end

    it 'thread-safe' do
      expect(conn.instance_eval { @mutex }).to receive(:synchronize)
      conn.disconnect
    end
  end
end
