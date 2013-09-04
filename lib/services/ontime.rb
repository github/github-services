class Service::OnTime < Service
  string :ontime_url, :api_key
  white_list :ontime_url

  self.title = 'OnTime'

  def receive_push
    raise_config_error 'No OnTime URL to connect to.' if data['ontime_url'].to_s.empty?
    raise_config_error 'No API Key.' if data['api_key'].to_s.empty?

    http.url_prefix = data['ontime_url']
    json = generate_json(payload)
    resp = http_get 'api/version'
    version = JSON.parse(resp.body)['data']
    curvers = "#{version['major']}.#{version['minor]']}"

    # Hash the data, it has to be hexdigest in order to have the same hash value in .NET
    hash_data = Digest::SHA256.hexdigest(json + data['api_key'])

    if (version['major'] == 11 and version['minor'] >= 1) or (version['major'] == 12 and version['minor'] < 2)
      result = http_post 'api/github', :payload => json, :hash_data => hash_data, :source => :github, :service_version => 1.0, :ontime_version => curvers
    elsif (version['major'] == 12 and version['minor'] >= 2) or (version['major'] == 13 and   version['minor'] < 3)
      result = http_post 'api/v1/github', :payload => json, :hash_data => hash_data, :source => :github, :service_version => 1.1, :ontime_version => curvers
    elsif (version['major'] == 13 and version['minor'] >= 3) or version['major'] > 13
      http.headers['Content-Type'] = 'application/json'
      result = http_post("api/v2/github?hash_data=#{hash_data}&ontime_version=#{curvers}&service_version=2.0", json)
    else
      raise_config_error 'Unexpected API version. Please update to the latest version of OnTime to use this service.'
    end

    verify_response(result)
  end

  def verify_response(res)
    case res.status
      when 200..299
      when 403, 401, 422 then raise_config_error("Invalid Credentials")
      when 404, 301, 302 then raise_config_error("Invalid URL")
      else raise_config_error("HTTP: #{res.status}")
    end
  end
end

