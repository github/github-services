secrets = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'secrets.yml'))

service :boxcar do |data, payload|
  provider_url = URI.parse("http://providers.boxcar.io/github/#{secrets['boxcar']['apikey']}")
  Net::HTTP.post_form(provider_url, 
    { :emails => data['subscribers'], :payload => JSON.generate(payload) })
end