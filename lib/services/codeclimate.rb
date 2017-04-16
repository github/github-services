class Service::CodeClimate < Service::HttpPost
  password :token

  default_events :push, :pull_request

  url "http://codeclimate.com"

  maintained_by :github => "calavera"

  supported_by :web => "https://codeclimate.com/contact",
    :email => "hello@codeclimate.com",
    :twitter => "@codeclimate"

  within_enterprise do
    string :codeclimate_endpoint
  end

  def receive_event
    token = required_config_value('token')

    http.basic_auth "github", token
    http.headers['X-GitHub-Host'] = github_enterprise_url if enterprise?

    delivery_endpoint = data.fetch(:codeclimate_endpoint, "https://codeclimate.com")
    deliver(URI.join(delivery_endpoint, "github_events").to_s, insecure_ssl: true)
  end

  def token
    data["token"].to_s.strip
  end
end
