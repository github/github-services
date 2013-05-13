class Service::Zendesk < Service
  default_events :commit_comment, :issues, :issue_comment, :pull_request, :push
  string   :subdomain, :username
  password :password
  white_list :subdomain, :username

  def invalid_request?
   data['username'].to_s.empty? or
   data['password'].to_s.empty? or
   data['subdomain'].to_s.empty?
  end

  def service_url(subdomain, ticket_id)
    if subdomain =~ /\./
      url = "https://#{subdomain}/api/v2/integrations/github?ticket_id=#{ticket_id}"
    else
      url = "https://#{subdomain}.zendesk.com/api/v2/integrations/github?ticket_id=#{ticket_id}"
    end

    begin
      Addressable::URI.parse(url)
    rescue Addressable::URI::InvalidURIError
      raise_config_error("Invalid subdomain #{subdomain}")
    end

    url
  end

  def receive_event
    raise_config_error "Missing or bad configuration" if invalid_request?

    if payload.inspect =~ /zd#(\d+)/i
      ticket_id = $1
    else
      return
    end

    http.basic_auth(data['username'], data['password'])
    http.headers['Content-Type'] = 'application/json'
    http.headers['Accept'] = 'application/json'
    http.headers['X-GitHub-Event'] = event.to_s

    url = service_url(data['subdomain'], ticket_id)
    res = http_post(url, generate_json(:payload => payload))

    if res.status != 201
      raise_config_error("Unexpected response code:#{res.status}")
    end
  end
end
