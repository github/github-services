class Service::Talker < Service
  string  :url, :token
  boolean :digest

  def receive_push
    repository = payload['repository']['name']
    branch     = branch_name
    commits    = payload['commits']
    token      = data['token']

    http.ssl[:verify] = false
    http.headers["X-Talker-Token"] = token
    http.url_prefix = data['url']

    if data['digest'].to_i == 1 and commits.size > 1
      http_post 'messages.json', :message => "#{summary_message} – #{summary_url}"
    else
      http_post 'messages.json', :message => "#{pusher_name} pushed the following commits:"
      commits.each do |commit|
        http_post 'messages.json', :message => "#{format_commit_message(commit)} - #{commit['url']}"
      end
    end
  end
end
