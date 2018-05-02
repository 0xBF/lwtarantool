require 'msgpack'

module LWTarantool
  class Connection
    attr_accessor :logger

    def call(func, args)
      mutex.synchronize do
        _connect unless connected?
        _call(func, args.to_msgpack)
      end
    rescue SystemError
      attempt ||= 0
      attempt += 1
      disconnect
      retry if attempt <= 1
      raise
    end

    def read
      mutex.synchronize do
        _read
      end
    rescue SystemError
      disconnect
      raise
    end

    def disconnect
      mutex.synchronize do
        _disconnect
      end
    end

    private

    def raise_exception
    end

    attr_reader :mutex
  end
end
