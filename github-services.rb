$:.unshift *Dir["#{File.dirname(__FILE__)}/vendor/**/lib"]
%w( rack sinatra tinder twitter json net/http socket timeout ).each { |f| require f }

post '/campfire/' do
  data       = JSON.parse(params[:data])
  payload    = JSON.parse(params[:payload])

  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)
  campfire.login data['email'], data['password']
  room       = campfire.find_room_by_name data['room']
  payload['commits'].each do |commit|
    commit = commit.last
    text   = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
    room.speak text
  end
end

post '/irc/' do
  data       = JSON.parse(params[:data])
  payload    = JSON.parse(params[:payload])

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
    irc.puts "PRIVMSG #{room} :\002\00311#{repository}\002 \0037#{branch} \0033#{commit['author']['name']}"
    irc.puts "PRIVMSG #{room} :#{commit['message']}"
    irc.puts "PRIVMSG #{room} :#{commit['url']}"
  end
  irc.puts "QUIT"
end

post '/lighthouse/' do
  data       = JSON.parse(params[:data])
  payload    = JSON.parse(params[:payload])

  payload['commits'].each do |commit_id, commit|
    added    = commit['added'].map    { |f| ['A', f] }
    removed  = commit['removed'].map  { |f| ['R', f] }
    modified = commit['modified'].map { |f| ['M', f] }
    diff     = YAML.dump(added + removed + modified)

    title = "Changeset [%s] by %s" % [commit_id, commit['author']['name']]
    body  = "#{commit['message']}\n#{commit['url']}"
    changeset_xml = <<-XML.strip
      <changeset>
        <title>#{CGI.escapeHTML(title)}</title>
        <body>#{CGI.escapeHTML(body)}</body>
        <changes type="yaml">#{CGI.escapeHTML(diff)}</changes>
        <revision>#{CGI.escapeHTML(commit_id)}</revision>
        <changed-at type="datetime">#{CGI.escapeHTML(commit['timestamp'])}</changed-at>
      </changeset>
    XML

    account = "http://#{data['subdomain']}.lighthouseapp.com"
    url = URI.parse('%s/projects/%d/changesets.xml' % [account, data['project_id']])
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth data['token'], 'x'
    req.body = changeset_xml
    req.set_content_type('application/xml')
    Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  end
end

post '/twitter/' do
  data       = JSON.parse(params[:data])
  payload    = JSON.parse(params[:payload])

  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  twitter    = Twitter::Base.new(data['username'], data['password'])
  begin
    Timeout::timeout(2) do
      url = Net::HTTP.get "tinyurl.com", "/api-create.php?url=#{commit['url']}"
    end
  rescue
  end
  url ||= commit['url']

  payload['commits'].each do |commit|
    commit = commit.last
    text   = "[#{repository}] #{url} #{commit['author']['name']} - #{commit['message']}"
    twitter.post text
  end
end
