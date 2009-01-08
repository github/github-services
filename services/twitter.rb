service :twitter do |data, payload|
  repository = payload['repository']['name']
  url = URI.parse("http://twitter.com/statuses/update.xml")

  payload['commits'].each do |commit|
    tiny_url = shorten_url(commit['url'])
    status   = "[#{repository}] #{tiny_url} #{commit['author']['name']} - #{commit['message']}"

    req = Net::HTTP::Post.new(url.path)
    req.basic_auth(data['username'], data['password'])
    req.set_form_data('status' => status, 'source' => 'github')

    Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  end
end
