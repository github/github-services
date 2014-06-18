require 'uri'
class Service::Apoio < Service
  default_events :issues
  string   :subdomain
  password :token

  def invalid_request?
   data['token'].to_s.empty? or
   data['subdomain'].to_s.empty?
  end

  def receive_issues
    raise_config_error "Missing or bad configuration" if invalid_request?

    http.headers['Content-Type'] = 'application/json'
    http.headers['Accept'] = 'application/json'
    http.headers['X-Subdomain'] = data['subdomain']
    http.headers['X-Api-Token'] = data['token']

    url = "https://api.apo.io/service/github"
    res = http_post(url, generate_json(:payload  => payload))

    if res.status != 200
      raise_config_error("Unexpected response code:#{res.status}")
    end
  end
end
