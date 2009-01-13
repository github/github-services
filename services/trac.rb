service :trac do |data, payload|
  url = URI.join(data['url'], '/github/', data['token'])
  Net::HTTP.post_form(url, payload)
end
