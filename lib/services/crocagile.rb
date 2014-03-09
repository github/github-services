class Service::Crocagile < Service
  string :project_key

  def receive_event
    raise_config_error "Please enter your Project Key (located via Project Settings screen)." if data['project_key'].to_s.empty?
    http.headers['Content-Type'] = 'application/json'
    json = { :user_data => data, :payload => payload }.to_json
    res = http_post "https://www.crocagile.com/api/integration/github", json
    p res
    if res.status < 200 || res.status > 299
      raise_config_error 'Unable to connect with Crocagile.'
    else
      resp = JSON.parse(res.body)
      if (resp['status'] == 0)
        raise_config_error resp['message']
      end
    end
  end
end
