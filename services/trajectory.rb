class Service::Trajectory < Service
  string :api_key

  def receive_push
    raise_config_error "Missing 'api_key'" if data['api_key'].to_s == ''

    http.headers['content-type'] = 'application/json'

    res = http_post "https://www.apptrajectory.com/api/payloads?api_key=#{data['api_key'].to_s}", JSON.generate(payload)

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
