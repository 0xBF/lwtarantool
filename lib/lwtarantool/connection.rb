# frozen_string_literal: true

require 'msgpack'

module LWTarantool
  # Class for work with Tarantool connections
  class Connection
    # attr_accessor :logger

    # Call a function in tarantool.
    #
    # Connection can be one-time reestablished in case of fail.
    #
    # @param [String] func the tarantool function for call.
    # @param [Array] args the tarantool function arguments.
    #
    # @example
    #   conn.call('box.slab.info', [])
    #
    # @return [LWTarantool::Request] a new request instance.
    #
    # @raise [LWTarantool::ResolvError] destination host can't be resolved.
    # @raise [LWTarantool::TimeoutError] connect timeout reached.
    # @raise [LWTarantool::LoginError] incorrect login or password.
    # @raise [LWTarantool::SystemError] connection failed.
    # @raise [LWTarantool::UnknownError] unknown error.
    #
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

    #
    # Read a single response from tarantool.
    #
    # Returns request instance and update already exists request object.
    #
    # All active requests will be terminated in case of connection fail.
    #
    # @example
    #   conn.call('box.slab.info', [])
    #
    # @return [LWTarantool::Request] a correspond request instance.
    #
    # @raise [LWTarantool::SyncError] incorrect tarantool response.
    # @raise [LWTarantool::SystemError] connection was closed.
    # @raise [LWTarantool::UnknownError] unknown error.
    #
    def read
      mutex.synchronize do
        _read
      end
    rescue SystemError
      disconnect
      raise
    end

    #
    # Close tarantool connection.
    #
    # All active requests will be terminated.
    #
    # @example
    #   conn.disconnect
    #
    def disconnect
      mutex.synchronize do
        _disconnect
      end
    end

    private

    attr_reader :mutex
  end
end
