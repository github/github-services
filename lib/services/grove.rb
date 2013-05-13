class Service::Grove < Service
  default_events :commit_comment, :gollum, :issues, :issue_comment, :pull_request, :push
  string :channel_token

  def receive_push
    token = data['channel_token'].to_s
    raise_config_error "Missing channel token" if token.empty?

    res = http_post "https://grove.io/api/services/github/#{token}", 
      :payload => generate_json(payload)
  end
end
