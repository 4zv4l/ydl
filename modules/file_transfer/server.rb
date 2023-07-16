#!/bin/ruby

require 'socket'
require 'logger'

UDP_PORT = 6666
TCP_PORT = 6667
Log = Logger.new($stdout)

# send file to client
# server: filename
# server: size
# server: send(file, size)
def upload_file(conn, path)
  conn.puts File.basename(path)
  conn.puts File.size(path)
  # conn.write File.read(path)
rescue
  Log.warn "Client left before finishing upload"
end

# client discovery
# client: ???
# server: ydl ok
def listen_client
  Log.info "Discovering on 0.0.0.0:#{UDP_PORT}"
  server = UDPSocket.new
  server.setsockopt(:SOCKET, :BROADCAST, true)
  ip, port = "0.0.0.0", UDP_PORT
  server.bind(ip, port)
  loop do
    _, info = server.recvfrom(1024)
    server.send "ydl ok", 0, info[2], info[1]
    Log.info "Sent discovery to client at #{info[2]}"
  end
end

# handle UDP client discovery
Thread.new { listen_client }
# handle TCP client download
musics = File.expand_path "~/Music/Musics/*.mp3"
server = TCPServer.open "0.0.0.0", TCP_PORT
Log.info "Listening on 0.0.0.0:#{TCP_PORT}"
loop do
  client = server.accept
  Log.info "Got a client at #{client.addr[2]}"
  Dir.glob(musics) do |music|
    upload_file(client, music)
  end
  client.close
  Log.info "Done with client :)"
end
