service :rubyforge do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  payload['commits'].each do |commit|
    id        = commit['id']
    rf        = RubyForge.new(data['username'], data['password'])
    group_id  = data['groupid']
    subject   = "Commit Notification (#{repository}/#{branch}): #{id}"
    body      = "`#{commit['message']}`, pushed by #{commit['author']['name']} (#{commit['author']['email']}). View more details for this change at #{commit['url']}."
    rf.post_news(group_id, subject, body)
  end
end
