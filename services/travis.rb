service :travis do |data, payload|
  user = (data['user'] || payload['repository']['owner']['name']).strip
  token = (data['token']).strip
  domain = (data['domain'] || 'http://travis-ci.org').strip

  scheme = (domain.to_s.scan(/^https?/).pop || 'http').strip

  travis_url = URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end

