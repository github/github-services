def build_cia_commit(data, repository, branch, sha1, commit, size = 1)
  log = commit['message']
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

service :cia do |data, payload|
  server = XMLRPC::Client.new2(
    if !(address = data['address'].to_s).empty?
      address
    else
      "http://cia.vc"
    end)

  repository =
    if !(name = data['project'].to_s).empty?
      name
    else
      payload['repository']['name']
    end

  branch =
    if (!branch = data['branch'].to_s).empty?
      branch.to_s % payload['ref_name']
    else
      payload['ref_name']
    end

  commits = payload['commits']

  if commits.size > 5
    message = build_cia_commit(data, repository, branch, payload['after'], commits.last, commits.size - 1)
    server.call("hub.deliver", message)
  else
    commits.each do |commit|
      sha1 = commit['id']
      message = build_cia_commit(data, repository, branch, sha1, commit)
      server.call("hub.deliver", message)
    end
  end
end
