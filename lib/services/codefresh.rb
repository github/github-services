class Service::Codefresh < Service::HttpPost
  url "https://codefresh.io"
  logo_url "https://codefresh.io/wp-content/themes/codefresh/images/logo.png"

  default_events :push, :pull_request

  maintained_by github: 'codefresh-io',
                twitter: '@codefresh'
  supported_by  web: 'https://codefresh.io',
                email: 'support@codefresh.io',
                twitter: '@codefresh'

  def receive_event
    http.headers['X-GitHub-Event'] = event.to_s
    http_post codefresh_url, payload: generate_json(payload)
  end

  private

  def codefresh_url
    "https://g.codefresh.io/api/providers/github/hook"
  end
end
