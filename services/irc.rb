service :irc do |data, payload|
  repository = payload['repository']['name']
  branch     = (payload['ref'] =~ /^refs\/heads\/(.+)$/ ? $1 : payload['ref'])
  rooms      = data['room'].gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
  botname    = "GitHub#{rand(200)}"
  socket     = nil

  begin
    Timeout.timeout(2) do
      socket = TCPSocket.open(data['server'], data['port'])
    end
  rescue Timeout::Error
    throw :halt, 400
  end

  if data['ssl'].to_i == 1
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.connect
    irc = ssl_socket
  else
    irc = socket
  end

  irc.puts "PASS #{data['password']}" unless data['password'].empty?
  irc.puts "NICK #{botname}"
  irc.puts "USER #{botname} 8 * :GitHub IRCBot"

  begin
    Timeout.timeout(10) do
      loop do
        case irc.gets
        when / 004 #{botname} /
          break
        when /^PING\s*:\s*(.*)$/
          irc.puts "PONG #{$1}"
        end
      end
    end
  rescue Timeout::Error
    throw :halt, 400
  end

  rooms.each do |room|
    room, pass = room.split("::")
    irc.puts "JOIN #{room} #{pass}"
    payload['commits'].each do |commit|
      sha1 = commit['id']

      tiny_url = shorten_url(commit['url'])

      irc.puts "PRIVMSG #{room} :\002#{repository}:\002 \0033#{commit['author']['name']} \00307#{branch}\0030 SHA1-\002#{sha1[0..6]}\002"
      irc.puts "PRIVMSG #{room} :#{commit['message']}"
      irc.puts "PRIVMSG #{room} :#{tiny_url}"
    end
    irc.puts "PART #{room}"
  end

  irc.puts "QUIT"
  irc.gets until irc.eof?
end
