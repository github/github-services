class Service::Acunote < Service
  string :token

  def receive_push
    res = http_post "https://www.acunote.com/source_control/github/%s" %
      [ data['token'] ],
      {'payload' => generate_json(payload)}

    if res.status != 200
      raise_config_error
    end
  end
end
