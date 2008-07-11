service :friendfeed do |data, payload|
  # You need your friendfeed nickname and your friendfeed 
  repository = payload['repository']['name']
  friendfeed_url = URI.parse("http://friendfeed.com/api/share")

  payload['commits'].each do |commit_id, commit|
    github_url, name, commit_msg = commit['url'], commit['author']['name'], commit['message']
    title = "#{name} just pushed #{commit_id} to #{repository} on GitHub"
    # This commit will be published to FriendFeed as 'Arun Thampi just pushed 56436bcdef2342ddfca234234 to github-services on GitHub'
    # with the comment set as 'Integrated FriendFeed in github-services'
    req = Net::HTTP::Post.new(friendfeed_url.path)
    req.basic_auth(data['nickname'], data['remotekey'])
    req.set_form_data(
      'title' => title, 'link' => github_url,
      'comment' => commit_msg
    )

    Net::HTTP.new(friendfeed_url.host, friendfeed_url.port).start { |http| http.request(req) }
  end
end
