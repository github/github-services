class Service::TestPilot < Service
  string :token

  def receive_push
    http.ssl[:verify] = false
    http_post test_pilot_url, {:payload => payload.to_json}.merge(authentication_token)
  end

  def test_pilot_url
    "http://testpilot.me/callbacks/github"
  end

  protected

  def authentication_param
    {:token => token}
  end
end

