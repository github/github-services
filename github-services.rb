$:.unshift *Dir["#{File.dirname(__FILE__)}/vendor/**/lib"]
%w( rack sinatra tinder twitter json net/http net/https socket timeout ).each { |f| require f }

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

post '/fogbugz/' do
  data        = JSON.parse(params[:data])
  payload     = JSON.parse(params[:payload])

  repository  = payload['repository']['name']
  branch      = payload['ref'].split('/').last
  before      = payload['before']   
  
  payload['commits'].each do |commit_id, commit|
    message = commit["message"]
    files   = commit["removed"] | commit["added"] | commit["modified"]
    
    # look for a bug id in each line of the commit message
    bug_list = []
    message.split("\n").each do |line|
      if (line =~ /\s*Bug[zs]*\s*IDs*\s*[#:; ]+((\d+[ ,:;#]*)+)/i)
        bug_list << $1.to_i
      end
    end
    
    # for each found bugzid, submit the files to fogbugz.
    bug_list.each do |fb_bugzid|
      files.each do |f|
        fb_repo = CGI.escape("#{repository}")
        fb_r1 = CGI.escape("#{before}")
        fb_r2 = CGI.escape("#{commit_id}")
        fb_file = CGI.escape("#{branch}/#{f}")
        
        #build the GET request, and send it to fogbugz
        fb_url = "#{data['cvs_submit_url']}?ixBug=#{fb_bugzid}&sRepo=#{fb_repo}&sFile=#{fb_file}&sPrev=#{fb_r1}&sNew=#{fb_r2}"
        url = URI.parse(fb_url)
        conn = Net::HTTP.new(url.host, url.port)
        conn.use_ssl = true
        conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
        conn.start do |http| 
          http.get(url.to_s)
        end

      end
    end
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
    text   = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
    irc.puts "PRIVMSG #{room} :#{text}"
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
