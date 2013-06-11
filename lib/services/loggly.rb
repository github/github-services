class Service::Loggly < Service
  string :input_token

  def receive_push
    http.headers['Content-Type'] = 'application/json'
    url = "https://logs.loggly.com/inputs/#{data['input_token']}"
    payload['commits'].each { |commit| http_post url, generate_json(commit) }
  end
end
