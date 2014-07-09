class Service::TestPilot < Service
  password :token

  def receive_push
    http.ssl[:verify] = false
    http.params.merge!(authentication_param)
    http_post test_pilot_url, :payload => generate_json(payload)
  end

  def test_pilot_url
    "http://testpilot.me/callbacks/github"
  end

  def token
    data['token'].to_s.strip
  end

  def authentication_param
    if token.empty?
      raise_config_error "Needs a token"
    end

    {:token => token}
  end
end

