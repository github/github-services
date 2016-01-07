class Service::Yammer < Service
  default_events :push, :commit_comment, :pull_request, :pull_request_review_comment, :public
  password :token

  def receive_event
    http_post "https://yammer-github.herokuapp.com/#{token}/notify/#{event}", :payload => generate_json(payload)
  end

  def token
    data["token"].to_s.strip
  end
end

