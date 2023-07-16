#!/bin/ruby

require 'socket'
require 'logger'

UDP_PORT = 6666
TCP_PORT = 6667
Log = Logger.new($stdout)

def download_file(conn, path)
  size = conn.gets.chomp
  mb_size = (size.to_f / 1024 / 1024).round(2)
  Log.info "Downloading \"#{path}\" of size #{mb_size} mb"
  # File.write(path, conn.read(size.to_i).chomp)
  Log.info "Downloaded \"#{path}\""
end

# server discovery
# client: ???
# server: ydl ok
# return server ip
def find_server_ip
  Log.info "Looking for server(s)"
  client = UDPSocket.new
  client.setsockopt(:SOCKET, :BROADCAST, true)
  ip, port = "255.255.255.255", UDP_PORT
  loop do
    client.send "???", 0, ip, port
    data, info = client.recvfrom(1024)
    if data.chomp == "ydl ok"
      Log.info "Found a server at #{info[2]}"
      return info[2]
    end
  end
end

ip = find_server_ip
TCPSocket.open(ip, TCP_PORT) do |conn|
  Log.info "Connected to #{ip}:#{TCP_PORT}"
  while (path = conn.gets)
    download_file(conn, path.chomp)
  end
  Log.info "Done downloading musics :)"
end
