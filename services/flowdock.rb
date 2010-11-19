service :flowdock do |data, payload|
  raise GitHub::ServiceConfigurationError, "Missing token" if data['token'].to_s.empty?

  url = URI.parse("http://api.flowdock.com/v1/git")
  Net::HTTP.post_form(url, {
    :token => data['token'],
    :payload => JSON.generate(payload),
  })
end
