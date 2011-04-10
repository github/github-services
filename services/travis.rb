service :travis do |data, payload|
  user = if data['user'].to_s == ''
           payload['repository']['owner']['name']
         else
           data['user']
         end.strip

  token = data['token'].strip

  full_domain = if data['domain'].to_s == ''
                  'http://travis-ci.org'
                else
                  data['domain']
                end.strip

  scheme, domain = full_domain.split('://')
  scheme, domain = 'http', scheme if domain.nil?

  travis_url = URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")

  Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
  nil
end

