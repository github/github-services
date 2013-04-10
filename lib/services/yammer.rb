class Service::Yammer < Service
  string :token

  def receive_push
    http_post "https://yammer-github.herokuapp.com/#{token}/notify/push", :payload => payload.to_json
  end

  def token
    data["token"].to_s.strip
  end
end

