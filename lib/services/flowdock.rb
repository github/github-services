require 'uri'

class Service::Flowdock < Service
  default_events :commit_comment, :gollum, :issues, :issue_comment, :pull_request, :push
  string :token

  def receive_event
    raise_config_error "Missing token" if data['token'].to_s.empty?

    data['token'].to_s.split(",").each do |t|
      token = URI.escape(t.to_s.gsub(/\s/, ''))

      http.headers['X-GitHub-Event'] = event.to_s
      http.headers['content-type'] = 'application/json'
      http_post "https://api.flowdock.com/v1/github/#{token}", generate_json(payload)
    end
  end
end
