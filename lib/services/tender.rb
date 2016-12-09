class Service::Tender < Service
  # mysite.tenderapp.com
  string :domain

  # tracker token. can be found here:
  # http://mysite.tenderapp.com/settings/trackers
  password :token

  default_events :issues, :pull_request

  url 'https://tenderapp.com'
  logo_url 'https://tenderapp.com/images/logo.jpg'

  # julien on http://help.tenderapp.com/home
  maintained_by :github => 'calexicoz'

  # Support channels for user-level Hook problems (service failure, misconfigured)
  supported_by :web => 'http://help.tenderapp.com/home',
               :email => 'support@tenderapp.com'

  def receive_issues
    raise_config_error 'Missing token' if data['token'].to_s.empty?
    raise_config_error 'Missing domain' if data['domain'].to_s.empty?

    begin
      # Nothing to see here really, just reposting the payload as-is
      http.headers['content-type'] = 'application/json'
      http.ssl[:verify] = false
      body = generate_json(payload)
      url = "https://#{data['domain']}/tickets/github/#{data['token']}"
      http_post url, body

    # Shamelessly copied from the 'web' service
    rescue Addressable::URI::InvalidURIError, Errno::EHOSTUNREACH
      raise_missing_error $!.to_s
    rescue SocketError
      if $!.to_s =~ /getaddrinfo:/
        raise_missing_error "Invalid host name."
      else
        raise
      end
    rescue EOFError
      raise_config_error "Invalid server response. Make sure the URL uses the correct protocol."
    end
  end

  alias receive_pull_request receive_issues
end
