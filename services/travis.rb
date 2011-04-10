service :travis do |data, payload|
  user = ((data['user'].to_s == '') ? payload['repository']['owner']['name'] : data['user']).strip
  token = data['token'].strip
  domain = ((data['domain'].to_s == '') ? 'http://travis-ci.org' : data['domain']).strip
  scheme, domain = data['domain'].strip.split '://'
  scheme, domain = 'http', scheme if domain.nil?

  travis_url = URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end

