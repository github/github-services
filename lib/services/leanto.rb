class Service::Leanto < Service
  string :token

  self.title = 'Lean-To'

  def receive_push
    res = http_post "http://www.lean-to.com/api/%s/commit" %
      [ data['token'] ],
      {'payload' => generate_json(payload)}

    if res.status != 200
      raise_config_error
    end
  end
end
