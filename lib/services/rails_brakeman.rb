class Service::RailsBrakeman < Service
  string :rails_brakeman_url, :token
  white_list :rails_brakeman_url

  def receive_push
    http_post rails_brakeman_url, :token => token, :payload => payload.to_json
  end

  def rails_brakeman_url
    if !(url = data["rails_brakeman_url"].to_s).empty?
      url.strip
    else
      "https://rails-brakeman.com"
    end
  end

  def token
    data['token'].strip
  end
end
