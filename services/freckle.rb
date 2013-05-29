class Service::Freckle < Service
  string :subdomain, :project, :token

  def receive_push
    entries, subdomain, token, project =
      [], data['subdomain'].strip, data['token'].strip, data['project'].strip

    payload['commits'].each do |commit|
      entries << {
        :date => commit["timestamp"],
        :message => commit["message"].strip,
        :url => commit['url'],
        :project_name => project,
        :author_email => commit['author']['email']
      }
    end

    http.headers['Content-Type'] = 'application/json'
    http_post "http://#{data['subdomain']}.letsfreckle.com/api/github/commits",
      {:entries => entries, :token => data['token']}.to_json
  end
end
