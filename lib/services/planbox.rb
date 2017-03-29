class Service::Planbox < Service
  password :token

  def receive_push
    token = data['token']
    res = http_post 'https://www.planbox.com/api/github_commits' do |req|
      req.params[:token] = data['token']
      req.body = {:payload => generate_json(payload)}
    end

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end

