require_relative 'spec_helper'

describe 'LWTarantool' do
  before(:each) { start_tarantool }
  after(:each) { stop_tarantool }

  it '.new returns LWTarantool::Connection' do
    expect(LWTarantool.new(url: 'tcp://127.0.0.1:3301')).to be_a LWTarantool::Connection
  end
end
