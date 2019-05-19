# frozen_string_literal: true

require 'tempfile'
require 'socket'

module RSpecHelpers
  module Tarantool
    def start_tarantool(conf = '')
      check_tarantool_not_started!

      @tarantool_dir = Dir.mktmpdir
      write_tarantool_config(@tarantool_dir, conf)

      @tarantool_pid = fork do
        Dir.chdir(@tarantool_dir)
        STDIN.reopen('/dev/null')
        STDOUT.reopen('tarantool.log')
        STDERR.reopen(STDOUT)
        exec 'tarantool init.lua'
      end

      wait_tarantool_start
    rescue StandardError
      FileUtils.remove_entry(@tarantool_dir) rescue nil
      raise
    end

    def write_tarantool_config(dir, conf)
      conf = [
        conf.to_s,
        'box.cfg{}',
        'box.schema.user.grant("guest", "read,write,execute", "universe")',
        'box.cfg{listen=3301}'
      ].join("\n")

      script = File.join(dir, 'init.lua')

      IO.write(script, conf)
    end

    def tarantool_log
      File.read(File.join(@tarantool_dir, 'tarantool.log'))
    end

    def stop_tarantool
      Process.kill(:KILL, @tarantool_pid) rescue nil
      Process.wait(@tarantool_pid) rescue nil
      FileUtils.remove_entry(@tarantool_dir) rescue nil
      @tarantool_pid = nil
      @tarantool_dir = nil

      check_tarantool_not_started! 'Can\' stop tarantool'
    end

    def check_tarantool_not_started!(message = 'Port 3301 is not available')
      TCPSocket.new '127.0.0.1', 3301
    rescue Errno::ECONNREFUSED
      true
    else
      raise message
    end

    def wait_tarantool_start
      100.times.reverse_each do |i|
        begin
          TCPSocket.new '127.0.0.1', 3301
          break
        rescue Errno::ECONNREFUSED
          sleep 0.05
          retry if i > 0

          STDERR.puts tarantool_log
          raise 'Tarantool is down'
        end
      end
    end
  end
end
