service :irc do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  rooms      = data['room'].gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}
  irc        = TCPSocket.open(data['server'], data['port'])
  irc.puts "USER blah blah blah :blah blah"
  irc.puts "NICK hubbub"
  rooms.each do |room|
    irc.puts "JOIN #{room}"
    payload['commits'].each do |sha1, commit|
      irc.puts "PRIVMSG #{room} :\002\00311#{repository}\002 \0037#{branch}\0030 SHA1-#{sha1[0..6]} \0033#{commit['author']['name']}"
      irc.puts "PRIVMSG #{room} :#{commit['message']}"
      irc.puts "PRIVMSG #{room} :#{commit['url']}"
    end
    irc.puts "PART #{room}"
  end
  irc.puts "QUIT"
end
