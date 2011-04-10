service :travis do |data, payload|
  user = ((data['user'].to_s == '') ? payload['repository']['owner']['name'] : data['user']).strip
  token = (data['token']).strip
  domain = ((data['domain'].to_s == '') ? 'http://travis-ci.org' : data['domain']).strip

  scheme = (domain.to_s.scan(/^https?/).pop || 'http').strip

  travis_url = URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end

