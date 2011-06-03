class Service::Acunote < Service
  self.hook_name = :acunote

  def receive_push
    res = http_post "https://www.acunote.com/source_control/github/%s" %
      [ data['token'] ],
      {'payload' => payload.to_json}

    if res.status != 200
      raise_config_error
    end
  end
end
