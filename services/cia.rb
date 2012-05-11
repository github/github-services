class Service::CIA < Service
  string :address, :project, :branch
  boolean :long_url
  white_list :address, :project, :branch

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

    commits = payload['commits']

    if commits.size > 5
      message = build_cia_commit(repository, branch, payload['after'], commits.last, commits.size - 1)
      deliver(message)
    else
      commits.each do |commit|
        sha1 = commit['id']
        message = build_cia_commit(repository, branch, sha1, commit)
        deliver(message)
      end
    end
  end

  attr_writer :xmlrpc_server
  def xmlrpc_server
    @xmlrpc_server ||= begin
      XMLRPC::Client.new2(
        (address = data['address'].to_s).present? ?
          address : 'http://cia.vc')
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

  def build_cia_commit(repository, branch, sha1, commit, size = 1)
    log = commit['message'].split("\n")[0]
    log << " (+#{size} more commits...)" if size > 1

    dt         = DateTime.parse(commit['timestamp']).new_offset
    timestamp  = Time.send(:gm, dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec).to_i
    files      = commit['modified'] + commit['added'] + commit['removed']
    tiny_url   = data['long_url'].to_i == 1 ? commit['url'] : shorten_url(commit['url'])

    log << " - #{tiny_url}"

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
