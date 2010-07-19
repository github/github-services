service :flowdock do |data, payload|
  raise GitHub::ServiceConfigurationError, "Missing token" if data['api_token'].to_s.empty?

  url = URI.parse("http://api.flowdock.com/v1/git")
  Net::HTTP.post_form(url, {
    :token => data['api_token'],
    :payload => JSON.generate(payload),
  })
end
