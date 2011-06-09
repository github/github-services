class Service::IRC < Service
  self.hook_name = :irc

  def receive_push
    next if payload['commits'].empty?

    repository = payload['repository']['name']
    branch     = payload['ref_name']
    rooms      = data['room'].gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
    botname    = data['nick'].to_s.empty? ? "GitHub#{rand(200)}" : data['nick']

    messages =
      payload['commits'].map do |commit|
        short  = commit['message'].split("\n", 2).first.to_s
        short += ' ...' if short != commit['message']
        author = commit['author']['name']
        sha1   = commit['id']
        files  = Array(commit['modified'])
        dirs   = files.map { |file| File.dirname(file) }.uniq
        if data['no_colors'].to_i == 1
            "#{repository}: #{branch} #{author} * " +
            "#{sha1[0..6]} (#{files.size} files in #{dirs.size} dirs): #{short}"
        else
            "\002#{repository}:\002 \00307#{branch}\003 \00303#{author}\003 * " +
            "\002#{sha1[0..6]}\002 (#{files.size} files in #{dirs.size} dirs): #{short}"
        end
      end

    if messages.size > 1
      before, after = payload['before'][0..6], payload['after'][0..6]
      compare_url   = payload['repository']['url'] + "/compare/#{before}...#{after}"
      tiny_url      = data['long_url'].to_i == 1 ? compare_url : shorten_url(compare_url)
      if data['no_colors'].to_i == 1
          summary = "#{repository}: #{branch} commits " +
                    "#{before}...#{after} - #{tiny_url}"
      else
          summary = "\002#{repository}:\002 \00307#{branch}\003 commits " +
                    "\002#{before}\002...\002#{after}\002 - #{tiny_url}"
      end
      messages << summary
    else
      commit   = payload['commits'][0]
      url      = commit['url']
      tiny_url = data['long_url'].to_i == 1 ? url : shorten_url(url)
      messages[0] << " - #{tiny_url}"
    end

    self.puts "PASS #{data['password']}" if data['password'] && !data['password'].empty?
    self.puts "NICK #{botname}"
    self.puts "USER #{botname} 8 * :GitHub IRCBot"

    loop do
      case self.gets
      when / 004 #{botname} /
        break
      when /^PING\s*:\s*(.*)$/
        self.puts "PONG #{$1}"
      end
    end

    without_join = data['message_without_join'] == '1'
    rooms.each do |room|
      room, pass = room.split("::")
      self.puts "JOIN #{room} #{pass}" unless without_join

      messages.each do |message|
        self.puts "PRIVMSG #{room} :#{message}"
      end

      self.puts "PART #{room}" unless without_join
    end

    self.puts "QUIT"
    self.gets until self.eof?
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

  def gets
    irc.gets
  end

  def eof?
    irc.eof?
  end

  def puts(*args)
    irc.puts *args
  end

  def irc
    @irc ||= begin
      socket = TCPSocket.open(data['server'], data['port'])
    end

    if data['ssl'].to_i == 1
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
      ssl_socket.sync_close = true
      ssl_socket.connect
      ssl_socket
    else
      socket
    end
  end
end
