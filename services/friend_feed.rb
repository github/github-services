service :friend_feed do |data, payload|
  repository = payload['repository']['name']
  friendfeed_url = URI.parse("http://friendfeed.com/api/share")

  payload['commits'].each do |commit|
    title = "#{commit['author']['name']} just committed a change to #{repository} on GitHub"
    comment = "#{commit['id']} - #{commit['message']}"

    req = Net::HTTP::Post.new(friendfeed_url.path)
    req.basic_auth(data['nickname'], data['remotekey'])
    req.set_form_data('title' => title, 'link' => commit['url'], 'comment' => comment, 'via' => 'github')

    Net::HTTP.new(friendfeed_url.host, friendfeed_url.port).start { |http| http.request(req) }
  end
end
