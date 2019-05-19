# frozen_string_literal: true

require_relative 'spec_helper'

describe 'LWTarantool::Request' do
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

  context 'returned by Connection#call' do
    it 'is not ready' do
      expect(conn.call('test1', []).ready?).to eq false
    end
  end

  context '#wait' do
    it 'wait for request ready' do
      req = conn.call('test1', [])
      expect(req.ready?).to eq false
      req.wait
      expect(req.ready?).to eq true
    end

    it 'update request status' do
      req = conn.call('test1', [])
      req.wait
      expect(req.result).to eq [[1, 2, 3]]
    end
  end

  context '#result' do
    it 'wait for request ready' do
      req = conn.call('test1', [])
      expect(req).to receive(:wait)
      req.result
    end

    it 'returns data when request ready' do
      req = conn.call('test1', [])
      req.wait
      expect(req.result).to eq [[1, 2, 3]]
    end

    it 'returns nil when request failed' do
      conn
      stop_tarantool
      req = conn.call('test1', [])
      req.wait rescue nil
      expect(req.error).not_to be_nil
      expect(req.result).to be_nil
    end
  end

  context '#error' do
    it 'wait for request ready' do
      req = conn.call('test1', [])
      expect(req).to receive(:wait)
      req.error
    end

    it 'returns nil when request success' do
      req = conn.call('test1', [])
      expect(req.error).to be_nil
    end

    it 'returns string when request failed' do
      conn
      stop_tarantool
      req = conn.call('test1', []) rescue nil
      req.wait rescue nil
      expect(req.error).to match(/canceled/)
    end
  end
end
