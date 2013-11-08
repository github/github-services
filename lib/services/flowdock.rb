require 'uri'

class Service::Flowdock < Service
  default_events :commit_comment, :gollum, :issues, :issue_comment, :pull_request, :push
  string :token

  url "https://www.flowdock.com"
  logo_url "https://d2ph5hv9wbwvla.cloudfront.net/github/icon_220x140.png"
  maintained_by :email => "team@flowdock.com"
  supported_by :email => "support@flowdock.com", :twitter => "@flowdock"

  def receive_event
    raise_config_error "Missing token" if data['token'].to_s.empty?
    token = URI.escape(data['token'].to_s.gsub(/\s/, ''))
    http.headers['X-GitHub-Event'] = event.to_s
    http.headers['content-type'] = 'application/json'
    http_post "https://api.flowdock.com/v1/github/#{token}", generate_json(payload)
  end
end
