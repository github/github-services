class Service::IRC < Service
  string   :server, :port, :room, :nick, :branch_regexes
  password :password
  boolean  :ssl, :message_without_join, :no_colors, :long_url, :notice
  white_list :server, :port, :room, :nick

  def receive_push
    return if distinct_commits.empty?
    return unless branch_name_matches?

    url  = data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)

    messages = []
    messages << "#{summary_message}: #{url}"
    messages += commit_messages.first(3)
    send_messages messages
  end

  def receive_pull_request
    return unless opened?

    url  = data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)

    send_messages "#{summary_message}: #{url}"
  end

  alias receive_issues receive_pull_request

  def send_messages(messages)
    rooms = data['room'].to_s
    if rooms.empty?
      raise_config_error "No rooms: #{rooms.inspect}"
      return
    end

    rooms   = rooms.gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
    botname = data['nick'].to_s.empty? ? "GitHub#{rand(200)}" : data['nick']
    command = data['notice'].to_i == 1 ? 'NOTICE' : 'PRIVMSG'

    self.puts "PASS #{data['password']}" if !data['password'].to_s.empty?
    self.puts "NICK #{botname}"
    self.puts "MSG NICKSERV IDENTIFY #{data['nickservidentify']}" if !data['nickservidentify'].to_s.empty?
    self.puts "USER #{botname} 8 * :GitHub IRCBot"

    loop do
      case self.gets
      when / 00[1-4] #{Regexp.escape(botname)} /
        break
      when /^PING\s*:\s*(.*)$/
        self.puts "PONG #{$1}"
      end
    end

    without_join = data['message_without_join'] == '1'
    rooms.each do |room|
      room, pass = room.split("::")
      self.puts "JOIN #{room} #{pass}" unless without_join

      Array(messages).each do |message|
        self.puts "#{command} #{room} :#{message}"
      end

      self.puts "PART #{room}" unless without_join
    end

    self.puts "QUIT"
    self.gets until self.eof?
  rescue SocketError => boom
    if boom.to_s =~ /getaddrinfo: Name or service not known/
      raise_config_error 'Invalid host'
    elsif boom.to_s =~ /getaddrinfo: Servname not supported for ai_socktype/
      raise_config_error 'Invalid port'
    else
      raise
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    raise_config_error 'Invalid host'
  rescue OpenSSL::SSL::SSLError
    raise_config_error 'Host does not support SSL'
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

      if data['ssl'].to_i == 1
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        ssl_socket.sync_close = true
        ssl_socket.connect
        socket = ssl_socket
      end

      socket
    end
  end

  def format_commit_message(commit)
    short  = commit['message'].split("\n", 2).first.to_s
    short += '...' if short != commit['message']

    author = commit['author']['name']
    sha1   = commit['id']
    files  = Array(commit['modified'])
    dirs   = files.map { |file| File.dirname(file) }.uniq

    if data['no_colors'].to_i == 1
        "#{repo_name}: #{branch_name} #{author} * " +
        "#{sha1[0..6]} (#{files.size} files in #{dirs.size} dirs): #{short}"
    else
        "\002#{repo_name}:\002 \00307#{branch_name}\003 \00303#{author}\003 * " +
        "\002#{sha1[0..6]}\002 (#{files.size} files in #{dirs.size} dirs): #{short}"
    end
  end
  
  def branch_name_matches?
    return true if data['branch_regexes'].nil?
    return true if data['branch_regexes'].strip == ""
    branch_regexes = data['branch_regexes'].split(',')
    branch_regexes.each do |regex|
      return true if Regexp.new(regex) =~ branch_name
    end
    false
  end
end
