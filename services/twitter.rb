service :twitter do |data, payload|
  repository = payload['repository']['name']
  url = URI.parse("http://twitter.com/statuses/update.xml")
  statuses = Array.new

  if data['digest'] == '1'
    commit = payload['commits'][-1]
    tiny_url = shorten_url(payload['repository']['url'] + '/commits/' + payload['ref'].split('/')[-1])
    statuses.push "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{payload['commits'].length} commits"
  else
    payload['commits'].each do |commit|
      tiny_url = shorten_url(commit['url'])
      statuses.push "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{commit['message']}"
    end
  end

  statuses.each do |status|
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth(data['username'], data['password'])
    req.set_form_data('status' => status, 'source' => 'github')

    Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  end
end
