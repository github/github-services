class Service::Talker < Service
  string  :url, :token
  boolean :digest

  def receive_push
    repository = payload['repository']['name']
    branch     = payload['ref_name']
    commits    = payload['commits']
    token      = data['token']

    http.ssl[:verify] = false
    http.headers["X-Talker-Token"] = token
    http.url_prefix = data['url']

    if data['digest'].to_i == 1
      commit = commits.last
      message = "[#{repository}/#{branch}] #{commit['message']} (+#{commits.size - 1} more commits...) - #{commit['author']['name']} #{commit['url']} )"

      http_post 'messages.json', :message => message
    else
      commits.each do |commit|
        message = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} #{commit['url']}"

        http_post 'messages.json', :message => message
      end
    end
  end
end
