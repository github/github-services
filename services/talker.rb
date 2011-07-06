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

    if data['digest'].to_i == 1 and commits.size > 1
      commit = commits.last
      message = "#{commit['author']['name']} pushed #{commits.size} commits to [#{repository}/#{branch}] #{payload['compare']}"
      http_post 'messages.json', :message => message
    else
      commits.each do |commit|
        message = "#{commit['author']['name']} pushed \"#{commit['message'].split("\n").first}\" -  #{commit['url']} to [#{repository}/#{branch}]"
        http_post 'messages.json', :message => message
      end
    end
  end
end
