class Service::Sifter < Service
  string :subdomain
  password :token

  def receive_push
    http.ssl[:verify] = false

    http_post hook_url do |req|
      req.params[:token]          = token
      req.headers['Content-Type'] = 'application/json'
      req.body                    = generate_json(payload)
    end
  end

  def hook_url
    # For development/troubleshooting, the host and protocol can be set
    # with the SIFTER_HOST variable, e.g. SIFTER_HOST=http://sifter.dev
    host  = ENV.fetch('SIFTER_HOST', 'sifterapp.com')
    proto = ENV.has_key?('SIFTER_HOST') ? 'http' : 'https'

    "#{proto}://#{subdomain}.#{host}/api/github"
  end

  def subdomain
    data["subdomain"].to_s.strip
  end

  def token
    data["token"].to_s.strip
  end

end

