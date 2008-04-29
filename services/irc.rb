service :irc do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  room       = data['room']
  room       = "##{room}" unless data['room'][0].chr == '#'
  irc        = TCPSocket.open(data['server'], data['port'])
  irc.puts "USER blah blah blah :blah blah"
  irc.puts "NICK hubbub"
  irc.puts "JOIN #{room}"
  payload['commits'].each do |commit|
    commit = commit.last
    text   = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
    irc.puts "PRIVMSG #{room} :#{text}"
  end
  irc.puts "QUIT"
end