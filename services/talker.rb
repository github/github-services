class Service::Talker < Service
  def receive_push
    repository = payload['repository']['name']
    branch = payload['ref_name']
    commits = payload['commits']
    token = data['token']

    http.ssl[:verify] = false
    http.headers["X-Talker-Token"] = token

    if data['digest'].to_i == 1
      commit = commits.last
      message = "[#{repository}/#{branch}] #{commit['message']} (+#{commits.size - 1} more commits...) - #{commit['author']['name']} #{commit['url']} )"

      http_post data['url'], :message => message
    else
      commits.each do |commit|
        message = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} #{commit['url']}"

        http_post data['url'], :message => message
      end
    end
  end
end
