require 'net/https'

service :flowdock do |data, payload|
  raise GitHub::ServiceConfigurationError, "Missing token" if data['api_token'].to_s.empty?

  def post_data(url_str, data)
    uri = URI.parse(url_str)
    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(data)
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.use_ssl = true
    end

    http.start { |http| http.request(req) }
  end

  post_data("https://api.flowdock.com/v1/git", {
    :token => data['api_token'],
    :payload => JSON.generate(payload),
  })
end
