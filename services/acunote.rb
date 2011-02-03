service :acunote do |data, payload|
  token = data['token']
  path = "/source_control/github/#{token}"

  req = Net::HTTP::Post.new(path)
  req.set_form_data('payload' => payload.to_json)
  req["Content-Type"] = 'application/x-www-form-urlencoded'

  http = Net::HTTP.new("www.acunote", 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  begin
    http.start do |connection|
      connection.request(req)
    end
  rescue Net::HTTPBadResponse
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  end
  nil
end
