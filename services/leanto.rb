class Service::Leanto < Service
  string :token

  def receive_push
    res = http_post "http://www.lean-to.com/api/%s/commit" %
      [ data['token'] ],
      {'payload' => payload.to_json}

    if res.status != 200
      raise_config_error
    end
  end
end