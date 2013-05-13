class Service::Irker < Service
  string :address, :project, :branch, :module, :channels
  boolean :long_url, :color, :full_commits
  white_list :address, :project, :branch, :module, :channels, :long_url, :color,
    :full_commits

  url 'http://www.catb.org/~esr/irker/'
  logo_url 'http://www.catb.org/~esr/irker/irker-logo.png'
  maintained_by :github => 'AI0867'
  supported_by :web => 'irc://chat.freenode.net/#irker'

  require 'json'

  def receive_push
    repository =
      if !(name = data['project'].to_s).empty?
        name
      else
        payload['repository']['name']
      end

    branch =
      if !(branch = data['branch'].to_s).empty?
        branch % branch_name
      else
        ref_name
      end

    module_name = data['module'].to_s

    commits = payload['commits']

    commits.each do |commit|
      sha1 = commit['id']
      messages = build_irker_commit(repository, branch, sha1, commit, module_name)
      messages.each do |message|
        deliver(message)
      end
    end
  end

  attr_writer :irker_con
  def irker_con
    @irker_con ||= begin
      address = data['address'].to_s
      if address.empty?
        address = "localhost"
      end
      TCPSocket.new address, 6659
    end
  end

  def deliver(message)
    irker_con.puts(message)
  end

  def build_irker_commit(repository, branch, sha1, commit, module_name)
    log_lines = commit['message'].split("\n")

    files      = commit['modified'] + commit['added'] + commit['removed']
    tiny_url   = data['long_url'].to_i == 1 ? commit['url'] : shorten_url(commit['url'])
    channels   = data['channels'].split(";")

    if data['color'].to_i == 1 then
      bold = "\x02"
      green = "\x0303"
      yellow = "\x0307"
      brown = "\x0305"
      reset = "\x0F"
    else
      bold = green = yellow = brown = reset = ''
    end

    files.uniq!
    file_string = files.join(",")
    if file_string.size > 80 and files.size > 1
      prefix = files[0]
      files.each do |file|
        while not file.match prefix
          prefix = prefix.rpartition("/")[0]
        end
      end
      file_string = "#{prefix}/ (#{files.size} files)"
    end

    messages = []
    if data['full_commits'].to_i == 1
      privmsg = <<-PRIVMSG
#{bold}#{repository}:#{reset} #{green}#{commit['author']['name']}#{reset} #{module_name}:#{yellow}#{branch}#{reset} * #{bold}#{sha1[0..6]}#{reset} / #{bold}#{file_string}#{reset}: #{brown}#{tiny_url}#{reset}
      PRIVMSG
      log_lines[0..4].each do |log_line|
        privmsg << <<-PRIVMSG
#{bold}#{repository}:#{reset} #{log_line[0..400]}
        PRIVMSG
      end
      messages.push generate_json({'to' => channels, 'privmsg' => privmsg.strip})
    else
      privmsg = <<-PRIVMSG
#{bold}#{repository}:#{reset} #{green}#{commit['author']['name']}#{reset} #{module_name}:#{yellow}#{branch}#{reset} * #{bold}#{sha1[0..6]}#{reset} / #{bold}#{file_string}#{reset}: #{log_lines[0][0..300]} #{brown}#{tiny_url}#{reset}
      PRIVMSG
      messages.push generate_json({'to' => channels, 'privmsg' => privmsg.strip})
    end
    return messages
  end
end
