service :twitter do |data, payload|
  repository = payload['repository']['name']
  url = URI.parse("http://twitter.com/statuses/update.xml")  
  statuses = Array.new

  if data['digest'] == false then #=> continue normal behaviour
    payload['commits'].each do |commit|
      tiny_url = shorten_url(commit['url'])
      statuses.push "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{commit['message']}"
    end
  else #=> Only post the latest commit
    payload['commits'].pop do |commit|
      tiny_url = shorten_url(commit['url'])
      statuses.push "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{payload['commits'].length} commits"
    end
  end

  statuses.each do |status|
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth(data['username'], data['password'])
    req.set_form_data('status' => status, 'source' => 'github')

    Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  end
end
