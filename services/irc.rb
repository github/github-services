class Service::IRC < Service
  string   :server, :port, :room, :nick, :branch_regexes
  password :password
  boolean  :ssl, :message_without_join, :no_colors, :long_url, :notice
  white_list :server, :port, :room, :nick

  default_events :push, :pull_request

  def receive_push
    return if distinct_commits.empty?
    return unless branch_name_matches?

    messages = []
    messages << "#{summary_message}: #{url}"
    messages += commit_messages.first(3)
    send_messages messages
  end

  def receive_pull_request
    return unless opened?

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

    irc_puts "PASS #{data['password']}" if !data['password'].to_s.empty?
    irc_puts "NICK #{botname}"
    irc_puts "MSG NICKSERV IDENTIFY #{data['nickservidentify']}" if !data['nickservidentify'].to_s.empty?
    irc_puts "USER #{botname} 8 * :GitHub IRCBot"

    loop do
      case irc_gets
      when / 00[1-4] #{Regexp.escape(botname)} /
        break
      when /^PING\s*:\s*(.*)$/
        irc_puts "PONG #{$1}"
      end
    end

    without_join = data['message_without_join'] == '1'
    rooms.each do |room|
      room, pass = room.split("::")
      irc_puts "JOIN #{room} #{pass}" unless without_join

      Array(messages).each do |message|
        irc_puts "#{command} #{room} :#{message}"
      end

      irc_puts "PART #{room}" unless without_join
    end

    irc_puts "QUIT"
    irc_response = []
    irc_response << irc_gets unless irc_eof?
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

  def irc_gets
    irc.gets
  end

  def irc_eof?
    irc.eof?
  end

  def irc_puts(*args)
    irc.puts *args
  end

  def irc
    @irc ||= begin
      socket = TCPSocket.open(data['server'], port)

      socket = new_ssl_wrapper(socket) if use_ssl?

      socket
    end
  end

  def new_ssl_wrapper(socket)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.connect
    ssl_socket
  end

  def use_ssl?
    data['ssl'].to_i == 1
  end

  def default_port
    use_ssl? ? 9999 : 6667
  end

  def port
    data['port'] || default_port
  end

  def url
    data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)
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
