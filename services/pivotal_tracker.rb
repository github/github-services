class Service::PivotalTracker < Service
  def receive_push
    token = data['token']

    # need to figure out how to get the right equifax secure ca loaded
    http.ssl[:verify] = false

    res = http_post 'https://www.pivotaltracker.com/services/v3/github_commits' do |req|
      req.params[:token] = data['token']
      req.body = {:payload => payload.to_json}
    end

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end

