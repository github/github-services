service :get_localization do |data, payload|
  project_name = data['project_name']
  project_token = data['project_token']

  path = "/services/github/notify/#{project_name}/#{project_token}/"

  req = Net::HTTP::Post.new(path)
  req.set_form_data('payload' => payload.to_json)
  req["Content-Type"] = 'application/x-www-form-urlencoded'

  http = Net::HTTP.new("getlocalization.com", 443)
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


