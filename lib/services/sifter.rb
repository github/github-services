class Service::Sifter < Service
  string :subdomain
  string :token

  def receive_push
    http.ssl[:verify] = false

    http_post hook_url do |req|
      req.params[:token]          = token
      req.headers['Content-Type'] = 'application/json'
      req.body                    = generate_json(payload)
    end
  end

  def hook_url
    host = ENV.fetch('SIFTER_HOST', 'sifterapp.com')
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

