service :travis do |data, payload|
  user = payload['repository']['owner']['name']
  token = data['token']

  travis_url = URI.parse("http://#{user}:#{token}@travis-ci.org/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end
