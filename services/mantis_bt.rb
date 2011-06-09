class Service::MantisBT < Service
  self.hook_name = :mantis_bt

  def receive_push
    http.url_prefix = data['url']
    res = http_post 'plugin.php', :payload => payload.to_json do |req|
      req.params.update \
        :page => "Source/checkin",
        :api_key => data['api_key']
    end

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  rescue Errno::ECONNREFUSED => boom
    raise_config_error "Connection refused. Invalid server URL."
  end
end
