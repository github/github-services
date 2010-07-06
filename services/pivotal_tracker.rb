service :pivotal_tracker do |data, payload|
  token = data['token']
  path = "/services/v3/github_commits?token=#{token}"

  req = Net::HTTP::Post.new(path)
  req.set_form_data('payload' => payload.to_json)
  req["Content-Type"] = 'application/x-www-form-urlencoded'

  http = Net::HTTP.new("www.pivotaltracker.com", 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.start do |connection|
    connection.request(req)
  end
  nil
end