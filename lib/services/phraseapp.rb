class Service::Phraseapp < Service::HttpPost
  title "PhraseApp"

  string :auth_token
  
  white_list :auth_token

  default_events :push

  url "https://phraseapp.com"
  logo_url "https://phraseapp.com/assets/github/phraseapp-logo.png"

  maintained_by github: "docstun"

  supported_by web: "https://phraseapp.com/contact",
    email: "info@phraseapp.com",
    twitter: "@phraseapp"

  def receive_push
    auth_token = required_config_value("auth_token")
    raise_config_error "Invalid auth token" unless auth_token.match(/^[A-Za-z0-9]+$/)

    body = generate_json(hook_params)
    http_post(hook_uri, body) do |request|
      request.params[:auth_token] = auth_token
    end
  end

protected
  def hook_uri
    "https://phraseapp.com:443/api/v1/hooks/github"
  end

  def hook_params
    {
      data: data,
      payload: payload
    }
  end
end
