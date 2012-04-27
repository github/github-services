require 'uri'
class Service::Apoio < Service
  default_events :issues
  string   :subdomain, :token

  def invalid_request?
   data['token'].to_s.empty? or
   data['subdomain'].to_s.empty?
  end

  def service_url(subdomain)
    url = "http://#{subdomain}.apo.io/service/github"

    begin
      URI.parse(url)
    rescue URI::InvalidURIError
      raise_config_error("Invalid subdomain #{subdomain}")
    end

    url
  end

  def receive_issues
    raise_config_error "Missing or bad configuration" if invalid_request?

    http.headers['Content-Type'] = 'application/json'
    http.headers['Accept'] = 'application/json'
    http.headers['X-Api-Token'] = data['token']

    url = service_url(data['subdomain'])
    res = http_post(url, { :payload  => payload }.to_json)

    if res.status != 200
      raise_config_error("Unexpected response code:#{res.status}")
    end
  end
end
