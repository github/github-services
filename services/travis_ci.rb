service :travis_ci do |data, payload|
  user = data['user'] || payload['repository']['owner']['name']
  token = data['token']
  domain = data['domain'] || 'http://travis-ci.org'

  scheme = domain.to_s.scan(/^https?/).pop || 'http'

  travis_url = URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end

