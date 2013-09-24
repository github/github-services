class Service::IRC < Service
  string   :server, :port, :room, :nick, :branch_regexes, :nickserv_password
  password :password
  boolean  :ssl, :message_without_join, :no_colors, :long_url, :notice
  white_list :server, :port, :room, :nick

  default_events :push, :pull_request

  def receive_push
    return unless branch_name_matches?

    messages = []
    messages << "#{irc_push_summary_message}: #{fmt_url url}"
    messages += distinct_commits.first(3).map {
        |commit| self.irc_format_commit_message(commit)
    }
    send_messages messages
  end

  def receive_commit_comment
    send_messages "#{irc_commit_comment_summary_message} #{fmt_url url}"
  end

  def receive_pull_request
    send_messages "#{irc_pull_request_summary_message}  #{fmt_url url}" if action =~ /(open)|(close)/
  end

  def receive_pull_request_review_comment
    send_messages "#{irc_pull_request_review_comment_summary_message}  #{fmt_url url}"
  end

  def receive_issues
    send_messages "#{irc_issue_summary_message}  #{fmt_url url}"
  end

  def receive_issue_comment
    send_messages "#{irc_issue_comment_summary_message} #{fmt_url url}"
  end

  def send_messages(messages)
    messages = Array(messages)

    if data['no_colors'].to_i == 1
      messages.each{|message|
        message.gsub!(/\002|\017|\026|\037|\003\d{0,2}(?:,\d{1,2})?/, '')}
    end

    rooms = data['room'].to_s
    if rooms.empty?
      raise_config_error "No rooms: #{rooms.inspect}"
      return
    end

    rooms   = rooms.gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
    botname = data['nick'].to_s.empty? ? "GitHub#{rand(200)}" : data['nick']
    command = data['notice'].to_i == 1 ? 'NOTICE' : 'PRIVMSG'

    irc_password("PASS", data['password']) if !data['password'].to_s.empty?
    irc_puts "NICK #{botname}"
    irc_puts "USER #{botname} 8 * :GitHub IRCBot"

    loop do
      case irc_gets
      when / 00[1-4] #{Regexp.escape(botname)} /
        break
      when /^PING\s*:\s*(.*)$/
        irc_puts "PONG #{$1}"
      end
    end

    nickserv_password = data['nickserv_password'].to_s
    if !nickserv_password.empty?
      irc_password("PRIVMSG NICKSERV :IDENTIFY", nickserv_password)
      loop do
        case irc_gets
        when /^:NickServ/i
          # NickServ responded somehow.
          break
        when /^PING\s*:\s*(.*)$/
          irc_puts "PONG #{$1}"
        end
      end
    end

    without_join = data['message_without_join'] == '1'
    rooms.each do |room|
      room, pass = room.split("::")
      irc_puts "JOIN #{room} #{pass}" unless without_join

      messages.each do |message|
        irc_puts "#{command} #{room} :#{message}"
      end

      irc_puts "PART #{room}" unless without_join
    end

    irc_puts "QUIT"
    irc_gets until irc_eof?
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
  ensure
    emit_debug_log
  end

  def irc_gets
    response = readable_irc.gets
    debug_incoming(clean_string_for_json(response)) unless !response || response.empty?
    response
  end

  def irc_eof?
    readable_irc.eof?
  end

  def irc_password(command, password)
    real_command = "#{command} #{password}"
    debug_command = "#{command} #{'*' * password.size}"
    irc_puts(real_command, debug_command)
  end

  def irc_puts(command, debug_command=command)
    debug_outgoing(debug_command)
    writable_irc.puts command
  end

  def debug_outgoing(command)
    irc_debug_log << ">> #{command.strip}"
  end

  def debug_incoming(command)
    irc_debug_log << "=> #{command.strip}"
  end

  def irc_debug_log
    @irc_debug_log ||= []
  end

  def emit_debug_log
    return unless irc_debug_log.any?
    receive_remote_call("IRC Log:\n#{irc_debug_log.join("\n")}")
  end

  def irc
    @irc ||= begin
      socket = TCPSocket.open(data['server'], port)
      socket = new_ssl_wrapper(socket) if use_ssl?
      socket
    end
  end

  alias readable_irc irc
  alias writable_irc irc

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
    data['port'] ? data['port'].to_i : default_port
  end

  def url
    data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)
  end

  ### IRC message formatting.  For reference:
  ### \002 bold   \003 color   \017 reset  \026 italic/reverse  \037 underline
  ### 0 white           1 black         2 dark blue         3 dark green
  ### 4 dark red        5 brownish      6 dark purple       7 orange
  ### 8 yellow          9 light green   10 dark teal        11 light teal
  ### 12 light blue     13 light purple 14 dark gray        15 light gray

  def fmt_url(s)
    "\00302\037#{s}\017"
  end

  def fmt_repo(s)
    "\00313#{s}\017"
  end

  def fmt_name(s)
    "\00315#{s}\017"
  end

  def fmt_branch(s)
    "\00306#{s}\017"
  end

  def fmt_tag(s)
    "\00306#{s}\017"
  end

  def fmt_hash(s)
    "\00314#{s}\017"
  end

  def irc_push_summary_message
    message = []
    message << "\00301[#{fmt_repo repo_name}\00301] #{fmt_name pusher_name}"

    if created?
      if tag?
        message << "tagged #{fmt_tag tag_name} at"
        message << (base_ref ? fmt_branch(base_ref_name) : fmt_hash(after_sha))
      else
        message << "created #{fmt_branch branch_name}"

        if base_ref
          message << "from #{fmt_branch base_ref_name}"
        elsif distinct_commits.empty?
          message << "at #{fmt_hash after_sha}"
        end

        num = distinct_commits.size
        message << "(+\002#{num}\017 new commit#{num != 1 ? 's' : ''})"
      end

    elsif deleted?
      message << "\00304deleted\017 #{fmt_branch branch_name} at #{fmt_hash before_sha}"

    elsif forced?
      message << "\00304force-pushed\017 #{fmt_branch branch_name} from #{fmt_hash before_sha} to #{fmt_hash after_sha}"

    elsif commits.any? and distinct_commits.empty?
      if base_ref
        message << "merged #{fmt_branch base_ref_name} into #{fmt_branch branch_name}"
      else
        message << "fast-forwarded #{fmt_branch branch_name} from #{fmt_hash before_sha} to #{fmt_hash after_sha}"
      end

    else
      num = distinct_commits.size
      message << "pushed \002#{num}\017 new commit#{num != 1 ? 's' : ''} to #{fmt_branch branch_name}"
    end

    message.join(' ')
  end

  def irc_format_commit_message(commit)
    short  = commit['message'].split("\n", 2).first.to_s
    short += '...' if short != commit['message']

    author = commit['author']['name']
    sha1   = commit['id']
    files  = Array(commit['modified'])
    dirs   = files.map { |file| File.dirname(file) }.uniq

    "#{fmt_repo repo_name}/#{fmt_branch branch_name} #{fmt_hash sha1[0..6]} " +
    "#{fmt_name commit['author']['name']}: #{short}"
  end

  def irc_issue_summary_message
    "[#{fmt_repo repo.name}] #{fmt_name sender.login} #{action} issue \##{issue.number}: #{issue.title}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def irc_issue_comment_summary_message
    short  = comment.body.split("\r\n", 2).first.to_s
    short += '...' if short != comment.body
    "[#{fmt_repo repo.name}] #{fmt_name sender.login} comment on issue \##{issue.number}: #{short}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def irc_commit_comment_summary_message
    short  = comment.body.split("\r\n", 2).first.to_s
    short += '...' if short != comment.body
    sha1   = comment.commit_id
    "[#{fmt_repo repo.name}] #{fmt_name sender.login} comment on commit #{fmt_hash sha1[0..6]}: #{short}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def irc_pull_request_summary_message
    base_ref = pull.base.label.split(':').last
    head_ref = pull.head.label.split(':').last
    head_label = head_ref != base_ref ? head_ref : pull.head.label

    "[#{fmt_repo repo.name}] #{fmt_name sender.login} #{action} pull request " +
    "\##{pull.number}: #{pull.title} (#{fmt_branch base_ref}...#{fmt_branch head_ref})"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def irc_pull_request_review_comment_summary_message
    short  = comment.body.split("\r\n", 2).first.to_s
    short += '...' if short != comment.body
    sha1   = comment.commit_id
    "[#{fmt_repo repo.name}] #{fmt_name sender.login} comment on pull request " +
    "\##{pull_request_number} #{fmt_hash sha1[0..6]}: #{short}"
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
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
