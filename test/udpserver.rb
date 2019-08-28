require 'socket'

server = UDPSocket.new
server.bind('0.0.0.0', 2000)

fd = IO.sysopen(File.expand_path('../server_log/udp_server.log', __FILE__), 'w')
io = IO.new(fd)
io.sync = true

while true
  begin
    mesg, sender = server.recvfrom_nonblock(16)

    puts mesg
    io << mesg

    server.send("#{mesg}", 0, sender[3], sender[1])

  rescue IO::WaitReadable
    IO.select([server])
    retry
  end
end

# echo "hello" | socat -t 1 - UDP:127.0.0.1:2000
