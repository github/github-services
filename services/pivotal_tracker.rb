class Service::PivotalTracker < Service
  self.hook_name = :pivotal_tracker

  def receive_push
    token = data['token']
    res = http_post 'https://www.pivotaltracker.com/services/v3/github_commits' do |req|
      req.params[:token] = data['token']
      req.body = {:payload => payload.to_json}
    end

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end

