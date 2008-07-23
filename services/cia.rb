def build_cia_commit(repository, branch, commit, size = 1)
  log = commit['message']
  log << " (+#{size} more commits...)" if size > 1

  dt = DateTime.parse(commit['timestamp']).new_offset
  timestamp = Time.send(:gm, dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec).to_i

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
          <log>#{log}</log>
          <url>#{commit['url']}</url>
          <files>
            <file> #{commit['modified'].join("</file>\n<file>")} </file>
          </files>
        </commit>
      </body>
    </message>
  MSG
end

service :cia do |data, payload|
  server = XMLRPC::Client.new2("http://cia.navi.cx")

  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  commits    = payload['commits']

  if commits.size > 5
    message = build_cia_commit(repository, branch, commits[payload['after']], commits.size)
    server.call("hub.deliver", message)
  else
    commits.each do |sha1, commit|
      message = build_cia_commit(repository, branch, commit)
      server.call("hub.deliver", message)
    end
  end
end
