service :cia do |data, payload|
  server = XMLRPC::Client.new2("http://cia.navi.cx")

  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  payload['commits'].each do |sha1, commit|
    message = %Q|
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
  <timestamp>#{commit['timestamp'].to_i}</timestamp>
  <body>
    <commit>
      <author>#{commit['author']['name']}</author>
      <revision>#{sha1[0..6]}</revision>
      <log>#{commit['message']}</log>
      <url>#{commit['url']}</url>
    </commit>
  </body>
</message>
|

    result = server.call("hub.deliver", message)
  end
end
