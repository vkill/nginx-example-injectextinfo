require 'socket'

server = TCPServer.new 2000

fd = IO.sysopen(File.expand_path('../server_log/tcp_server.log', __FILE__), 'w')
io = IO.new(fd)
io.sync = true

loop do
  Thread.start(server.accept) do |client|
    n = 0
    while line = client.gets
      n += 1

      puts line
      io << line

      break if line =~ /exit/
      client.puts "#{line}" if n > 2
    end

    client.puts "Bye"
    sleep 1
    client.close
  end
end

# echo "hello\nexit" | socat - TCP:127.0.0.1:2000
