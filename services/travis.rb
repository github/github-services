service :travis do |data, payload|
  user = (data['user'] || payload['repository']['owner']['name']).strip
  token = data['token'].strip
  scheme, domain = data['domain'].strip.split '://'
  scheme, domain = 'http', scheme if domain.nil?

  travis_url = URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end

