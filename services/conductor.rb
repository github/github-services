class Service::Conductor < Service
  string  :api_key
  white_list :api_key

  default_events :push

  url "https://conductor-app.com"
  logo_url "#{url}/logo-blue.png"

  maintained_by :github => 'Shuntyard'
  supported_by :email => 'support@conductor-app.com'

  def receive_push
    http.headers['X-GitHub-Event'] = event.to_s
    http_post "#{url}/github/commit/#{api_key}", {:payload => payload.to_json}
  end

end
