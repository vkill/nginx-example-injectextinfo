require 'test/unit'
require 'pathname'
require 'fileutils'
require 'open3'
require 'socket'

class IntegrationTest < Test::Unit::TestCase
  @@root = Pathname.new(File.expand_path('../..', __FILE__))

  class << self
    def execute(cmd)
      stdout_str, stderr_str, status = Open3.capture3(cmd)

      puts %Q`
================================================================================
cmd: #{cmd}
status: #{status}
stdout_str:
--------------------
#{stdout_str}
----------
stderr_str:
--------------------
#{stderr_str}
----------
========================================
`

      return [stdout_str, stderr_str, status]
    end

    def startup
      cmd_up = "docker-compose -f #{@@root.join('docker-compose.yml')} -p nginx-example-injectextinfo up -d"
      @@cmd_down = "docker-compose -f #{@@root.join('docker-compose.yml')} -p nginx-example-injectextinfo down"

      FileUtils.rm_rf Dir.glob(@@root.join('nginx_log_njs/*.log').to_s)
      FileUtils.rm_rf Dir.glob(@@root.join('test/server_log/*.log').to_s)

      stdout_str, stderr_str, status = execute(cmd_up)
      unless status.success?
        stdout_str, stderr_str, status = execute(@@cmd_down)
        if status.success?
          raise "failed to up services"
        else
          raise "failed to up services and down services"
        end
      end

      sleep 1
    end

    def shutdown
      stdout_str, stderr_str, status = execute(@@cmd_down)
      unless status.success?
        raise 'failed to down services'
      end
    end
  end

  def test_tcp_via_njs
    socket = TCPSocket.new '172.17.0.1', 17001
    socket.puts 'hello'
    socket.puts 'exit'
    text = socket.read
    socket.close

    assert_equal text, "hello\nBye\n"

    fd = IO.sysopen @@root.join('test/server_log/tcp_server.log').to_s, 'r'
    io = IO.new fd

    assert_equal io.readbyte, 0
    assert_equal io.readbyte, 3
    assert_equal io.readchar, 'f'
    assert_equal io.readchar, 'o'
    assert_equal io.readchar, 'o'
    assert_equal io.readbyte, 13
    assert_equal io.readbyte, 10

    proxy_protocol_str = io.readline
    assert proxy_protocol_str.start_with?('PROXY TCP4 ')
    assert proxy_protocol_str.end_with?("\r\n")

    assert_equal io.readchar, 'h'
    assert_equal io.readchar, 'e'
    assert_equal io.readchar, 'l'
    assert_equal io.readchar, 'l'
    assert_equal io.readchar, 'o'
    assert_equal io.readbyte, 10

    assert_equal io.readchar, 'e'
    assert_equal io.readchar, 'x'
    assert_equal io.readchar, 'i'
    assert_equal io.readchar, 't'
    assert_equal io.readbyte, 10

    assert io.eof?

    io.close
  end

  def test_udp_via_njs
    socket = UDPSocket.new
    socket.send 'hello', 0, '172.17.0.1', 17002
    socket.send 'world', 0, '172.17.0.1', 17002
    socket.close

    sleep 1

    fd = IO.sysopen @@root.join('test/server_log/udp_server.log').to_s, 'r'
    io = IO.new fd

    assert_equal io.readbyte, 0
    assert_equal io.readbyte, 6
    assert_equal io.readchar, 'b'
    assert_equal io.readchar, 'a'
    assert_equal io.readchar, 'r'
    assert_equal io.readchar, 'b'
    assert_equal io.readchar, 'a'
    assert_equal io.readchar, 'r'
    assert_equal io.readbyte, 13
    assert_equal io.readbyte, 10

    assert_equal io.readchar, 'h'
    assert_equal io.readchar, 'e'
    assert_equal io.readchar, 'l'
    assert_equal io.readchar, 'l'
    assert_equal io.readchar, 'o'

    assert_equal io.readchar, 'w'
    assert_equal io.readchar, 'o'
    assert_equal io.readchar, 'r'
    assert_equal io.readchar, 'l'
    assert_equal io.readchar, 'd'

    assert io.eof?

    io.close
  end
end
