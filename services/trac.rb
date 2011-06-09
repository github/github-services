class Service::Trac < Service
  self.hook_name = :trac

  def receive_push
    http.url_prefix = data['url']
    http_post "github/#{data['token']}", :payload => payload.to_json
  rescue Errno::ECONNREFUSED => boom
    raise GitHub::ServiceConfigurationError, "Connection refused. Invalid server URL."
  end
end
