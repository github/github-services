service :irc do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  rooms      = data['room'].gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
  botname    = "GitHub#{rand(200)}"
  socket     = TCPSocket.open(data['server'], data['port'])
  if data['ssl'].to_i == 1
    ssl_context = OpenSSL::SSL::SSLContext.new()
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE             # do not verify client certificates
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.connect
    irc = ssl_socket
  else
    irc = socket
  end
  irc.puts "PASS #{data['password']}" unless data['password'].empty?
  irc.puts "USER #{botname} #{botname} #{botname} :GitHub IRCBot"
  irc.puts "NICK #{botname}"
  rooms.each do |room|
    room, pass = room.split("::")
    irc.puts "JOIN #{room} #{pass}"
    payload['commits'].each do |commit|
      sha1 = commit['id']

      isgd_url = commit['url']
      Timeout::timeout(2) do
        isgd_url = Net::HTTP.get "is.gd", "/api.php?longurl=#{commit['url']}"
      end

      irc.puts "PRIVMSG #{room} :\002#{repository}:\002 \0033#{commit['author']['name']} \0037#{branch}\0030 SHA1-\002#{sha1[0..6]}\002"
      irc.puts "PRIVMSG #{room} :#{commit['message']}"
      irc.puts "PRIVMSG #{room} :#{isgd_url}"
    end
    irc.puts "PART #{room}"
  end
  irc.puts "QUIT"
end
