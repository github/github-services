class Service::PivotalTracker < Service
  string :token, :branch, :endpoint

  def receive_push
    token = data['token']
    branches = data['branch'].to_s.split(/\s+/)
    ref = payload["ref"].to_s

    notify if branches.empty? || branches.include?(ref.split("/").last)
  end

  def notify
    endpoint = data['endpoint'].to_s
    endpoint = 'https://www.pivotaltracker.com/services/v3/github_commits' if endpoint.empty?
    res = http_post endpoint do |req|
      req.params[:token] = data['token']
      req.body = {:payload => payload.to_json}
    end

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end

