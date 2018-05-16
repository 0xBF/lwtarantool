# frozen_string_literal: true

require 'msgpack'

module LWTarantool
  # Class for work with Tarantool requests
  class Request
    #
    # Correspond tarantool connection.
    #
    # @return [LWTarantool::Connection] correspond tarantool connection.
    #
    attr_reader :conn

    #
    # Wait for request be processed by Tarantool.
    #
    # @example
    #   req.wait
    #
    # @raise [LWTarantool::SyncError] incorrect tarantool response.
    # @raise [LWTarantool::SystemError] connection was closed.
    # @raise [LWTarantool::UnknownError] unknown error.
    #
    def wait
      conn.read until ready?
    end

    #
    # Wait for request processing and return tarantool reponse data.
    #
    # @example
    #   req.result
    #
    # @return [Array] response data if request was successfull processed.
    # @return [nil] nil if request failed.
    #
    def result
      wait unless ready?
      res = _result
      MessagePack.unpack(res) unless res.nil?
    end

    #
    # Wait for request processing and return tarantool error message.
    #
    # @example
    #   req.error
    #
    # @return [String] Tarantool error message if request failed.
    # @return [nil] nil if request success.
    #
    def error
      wait unless ready?
      _error
    end
  end
end
