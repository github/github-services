service :trac do |data, payload|
  begin
    #The data['url'] may contain a subdirectory, so this fails
    #url = URI.join(data['url'], '/github/', data['token'])
    url_value = data['url'].chomp('/')
    url = URI.parse("#{url_value}/github/#{data['token']}")
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({"payload" => payload.to_json})
    if url.user
      req.basic_auth url.user, url.password
    end
    http_session = Net::HTTP.new(url.host, url.port)
    http_session.use_ssl = true if url.port == 443
    http_session.start {|http| http.request(req)}
  rescue Net::HTTPBadResponse => boom
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  rescue Errno::ECONNREFUSED => boom
    raise GitHub::ServiceConfigurationError, "Connection refused. Invalid server URL."
  end
end
