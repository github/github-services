class Service::Codeship < Service::HttpPost
  string :project_uuid

  url "http://www.codeship.io"
  logo_url "http://www.codeship.io/logo_codeship_topbar.png"

  default_events :push, :pull_request

  maintained_by github: 'beanieboi',
                twitter: '@beanieboi'
  supported_by  web: 'http://www.codeship.io/contact',
                email: 'support@codeship.io',
                twitter: '@codeship'

  def receive_event
    http.headers['X-GitHub-Event'] = event.to_s
    http_post codeship_url, payload: generate_json(payload)
  end

  private

  def project_uuid
    required_config_value('project_uuid')
  end

  def codeship_url
    "https://lighthouse.codeship.io/github/#{project_uuid}"
  end
end
