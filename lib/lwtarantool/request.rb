require 'msgpack'

module LWTarantool
  class Request
    attr_reader :conn

    def wait
      conn.read until ready?
    end

    def result
      wait unless ready?
      res = _result
      MessagePack.unpack(res) unless res.nil?
    end

    def error
      wait unless ready?
      _error
    end
  end
end
