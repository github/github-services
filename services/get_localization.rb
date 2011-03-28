service :get_localization do |data, payload|
  project_name = data['project_id']
  project_token = data['project_token']
  
  gl_uri = "https://www.getlocalization.com/services/github/notify/#{project_name}/#{project_token}/"
  
  begin
    url = URI.parse(gl_uri)
    Net::HTTP.post_form(url, :payload => JSON.generate(payload))
  rescue Net::HTTPBadResponse
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  end
end