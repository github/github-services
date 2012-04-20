class Service::Rubyforge < Service
  string   :groupid, :username
  password :password
  white_list :groupid, :username

  def receive_push
    repository = payload['repository']['name']
    branch     = ref_name
    payload['commits'].each do |commit|
      id        = commit['id']
      group_id  = data['groupid']
      subject   = "Commit Notification (#{repository}/#{branch}): #{id}"
      body      = "`#{commit['message']}`, pushed by #{commit['author']['name']} (#{commit['author']['email']}). View more details for this change at #{commit['url']}."

      post_news(group_id, subject, body)
    end
  end

  def post_news(group_id, subject, body)
    rubyforge.post_news(group_id, subject, body)
  end

  def rubyforge
    @rubyforge ||= RubyForge.new(data['username'], data['password'])
  end
end
