class Service::Hostedgraphite < Service
  string :api_key

  def receive_push
    res = http_post "https://www.hostedgraphite.com/integrations/github/",
      'payload' => JSON.generate(payload),
      'api_key' => data['api_key']

    if res.status != 200
      raise_config_error
    end

  end
end

