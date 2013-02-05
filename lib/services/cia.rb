class Service::CIA < Service
  string :address, :project, :branch, :module
  boolean :long_url, :full_commits
  white_list :address, :project, :branch, :module

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

    if commits.size > 5
      message = build_cia_commit(repository, branch, payload['after'], commits.last, module_name, commits.size - 1)
      deliver(message)
    else
      commits.each do |commit|
        sha1 = commit['id']
        message = build_cia_commit(repository, branch, sha1, commit, module_name)
        deliver(message)
      end
    end
  end

  attr_writer :xmlrpc_server
  def xmlrpc_server
    @xmlrpc_server ||= begin
      XMLRPC::Client.new2(
        (address = data['address'].to_s).present? ?
          address : 'http://cia.vc/xmlrpc.php')
    end
  end

  def deliver(message)
    xmlrpc_server.call("hub.deliver", message)
  rescue StandardError => err
    if $!.to_s =~ /content\-type/i || $!.to_s =~ /HTTP\-Error/i
      raise_config_error "Check the CIA Address: #{$!.message}"
    else
      raise
    end
  end

  def build_cia_commit(repository, branch, sha1, commit, module_name, size = 1)
    log_lines = commit['message'].split("\n")
    log = log_lines.shift
    log << " (+#{size} more commits...)" if size > 1

    dt         = DateTime.parse(commit['timestamp']).new_offset
    timestamp  = Time.send(:gm, dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec).to_i
    files      = commit['modified'] + commit['added'] + commit['removed']
    tiny_url   = data['long_url'].to_i == 1 ? commit['url'] : shorten_url(commit['url'])

    log << " - #{tiny_url}"

    if data['full_commits'].to_i == 1
      log_lines.each do |log_line|
        log << "\n" << log_line
      end
    end

    <<-MSG
      <message>
        <generator>
          <name>github</name>
          <version>1</version>
          <url>http://www.github.com</url>
        </generator>
        <source>
          <project>#{repository}</project>
          <branch>#{branch}</branch>
          <module>#{module_name}</module>
        </source>
        <timestamp>#{timestamp}</timestamp>
        <body>
          <commit>
            <author>#{commit['author']['name']}</author>
            <revision>#{sha1[0..6]}</revision>
            <log>#{CGI.escapeHTML(log)}</log>
            <url>#{commit['url']}</url>
            <files>
              <file> #{files.join("</file>\n<file>")} </file>
            </files>
          </commit>
        </body>
      </message>
    MSG
  end
end
