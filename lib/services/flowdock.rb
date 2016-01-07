require 'uri'

class Service::Flowdock < Service::HttpPost
  default_events :commit_comment, :gollum, :issues, :issue_comment, :pull_request, :push, :pull_request_review_comment
  password :token

  url "https://www.flowdock.com"
  logo_url "https://d2ph5hv9wbwvla.cloudfront.net/github/icon_220x140.png"
  maintained_by email: "team@flowdock.com", github: 'Mumakil'
  supported_by email: "support@flowdock.com", twitter: "@flowdock"

  def receive_event
    raw_token = required_config_value('token')
    token = URI.escape(raw_token.to_s.gsub(/\s/, ''))
    http.headers['X-GitHub-Event'] = event.to_s
    deliver "https://api.flowdock.com/v1/github/#{token}"
  end

  def original_body
    payload
  end
end
