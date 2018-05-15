require 'tempfile'
require 'socket'

module RSpecHelpers
  module Tarantool
    def start_tarantool(conf='')
      begin
        TCPSocket.new '127.0.0.1', 3301
      rescue
      else
        raise RuntimeError, "port 3301 already used"
      end

      conf = [
        conf.to_s,
        "box.cfg{}",
        "box.schema.user.grant('guest', 'read,write,execute', 'universe')",
        "box.cfg{listen=3301}"
      ].join("\n")

      @tarantool_dir = Dir.mktmpdir
      script = File.join(@tarantool_dir, 'init.lua')

      IO.write(script, conf)

      @tarantool_pid = fork do
        Dir.chdir(@tarantool_dir)
        STDIN.reopen('/dev/null')
        STDOUT.reopen('tarantool.log')
        STDERR.reopen(STDOUT)
        exec 'tarantool init.lua'
      end

      100.times.reverse_each do |i|
        begin
          TCPSocket.new '127.0.0.1', 3301
          break
        rescue
          sleep 0.05
          retry if i > 0

          STDERR.puts tarantool_log
          raise RuntimeError, "Tarantool failed..." if i == 0
        end
      end
    rescue
      FileUtils.remove_entry(@tarantool_dir) rescue nil
      raise
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

      begin
        TCPSocket.new '127.0.0.1', 3301
      rescue
      else
        raise RuntimeError, "Can't stop tarantool"
      end
    end
  end
end
