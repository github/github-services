service :irc do |data, payload|
  begin
    next if payload['commits'].empty?

    repository = payload['repository']['name']
    branch     = payload['ref_name']
    rooms      = data['room'].gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
    botname    = data['nick'].to_s.empty? ? "GitHub#{rand(200)}" : data['nick']
    socket     = nil

    socket = TCPSocket.open(data['server'], data['port'])

    messages =
      payload['commits'].map do |commit|
        short  = commit['message'].split("\n", 2).first.to_s
        short += ' ...' if short != commit['message']
        author = commit['author']['name']
        sha1   = commit['id']
        files  = Array(commit['modified'])
        dirs   = files.map { |file| File.dirname(file) }.uniq
        "\002#{repository}:\002 \00307#{branch}\003 \00303#{author}\003 * " +
        "\002#{sha1[0..6]}\002 (#{files.size} files in #{dirs.size} dirs): #{short}"
      end

    if messages.size > 1
      before, after = payload['before'][0..6], payload['after'][0..6]
      compare_url   = payload['repository']['url'] + "/compare/#{before}...#{after}"
      tiny_url      = data['long_url'].to_i == 1 ? compare_url : shorten_url(compare_url)
      summary       = "\002#{repository}:\002 \00307#{branch}\003 commits " +
                "\002#{before}\002...\002#{after}\002 - #{tiny_url}"
      messages << summary
    else
      commit   = payload['commits'][0]
      url      = commit['url']
      tiny_url = data['long_url'].to_i == 1 ? url : shorten_url(url)
      messages[0] << " - #{tiny_url}"
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

    irc.puts "PASS #{data['password']}" if data['password'] && !data['password'].empty?
    irc.puts "NICK #{botname}"
    irc.puts "USER #{botname} 8 * :GitHub IRCBot"

    loop do
      case irc.gets
      when / 004 #{botname} /
        break
      when /^PING\s*:\s*(.*)$/
        irc.puts "PONG #{$1}"
      end
    end

    rooms.each do |room|
      room, pass = room.split("::")
      unless data['message_without_join'] == true
        irc.puts "JOIN #{room} #{pass}"
      end

      messages.each do |message|
        irc.puts "PRIVMSG #{room} :#{message}"
      end

      unless data['message_without_join'] == true
        irc.puts "PART #{room}"
      end
    end

    irc.puts "QUIT"
    irc.gets until irc.eof?
  rescue SocketError => boom
    if boom.to_s =~ /getaddrinfo: Name or service not known/
      raise GitHub::ServiceConfigurationError, "Invalid host"
    elsif boom.to_s =~ /getaddrinfo: Servname not supported for ai_socktype/
      raise GitHub::ServiceConfigurationError, "Invalid port"
    else
      raise
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    raise GitHub::ServiceConfigurationError, "Invalid host"
  rescue OpenSSL::SSL::SSLError
    raise GitHub::ServiceConfigurationError, "Host does not support SSL"
  end
end
