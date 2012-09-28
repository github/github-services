class Service::Irker < Service
  string :address, :project, :branch, :module, :channels
  boolean :long_url
  white_list :address, :project, :branch, :module, :channels

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
      # In the future, we want github to run its own irker instance
      # we can then put localhost here
      if address.empty?
        address = "master.atheme.org"
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

    file_string = files.join(" ")
    if file_string.size > 80 and files.size > 1
      prefix = files[0]
      files.each do |file|
        while not file.match prefix
          prefix = prefix.rpartition("/")[0]
        end
      end
      files = "#{prefix}/ (#{files.size} files)"
    end

    messages = []
    if data['full_commits'].to_i == 1
      privmsg = <<-PRIVMSG
        #{repository}: #{commit['author']['name']} #{module_name}:#{branch} * #{sha1[0..6]} / #{files.join(",")}: #{tiny_url}
      PRIVMSG
      messages.push JSON.generate({'to' => data['channels'], 'privmsg' => privmsg.strip})
      log_lines[0..4].each do |log_line|
        privmsg = <<-PRIVMSG
          #{repository}: #{log_line[0..400]}
        PRIVMSG
        messages.push JSON.generate({'to' => data['channels'], 'privmsg' => privmsg.strip})
      end
    else
      privmsg = <<-PRIVMSG
        #{repository}: #{commit['author']['name']} #{module_name}:#{branch} * #{sha1[0..6]} / #{files.join(",")}: #{log_lines[0][0..300]} #{tiny_url}
      PRIVMSG
      messages.push JSON.generate({'to' => data['channels'], 'privmsg' => privmsg.strip})
    end
    return messages
  end
end
