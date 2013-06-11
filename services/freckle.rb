class Service::Freckle < Service
  string :subdomain, :project, :token

  def receive_push
    subdomain, token, project = data['subdomain'].strip, data['token'].strip, data['project'].strip

    http.headers['Content-Type'] = 'application/json'
    http_post "http://#{data['subdomain']}.letsfreckle.com/api/github/commits",
      {:payload => payload, :token => data['token'], :project => project}.to_json
  end
end
