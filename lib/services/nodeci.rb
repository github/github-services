class Service::HubCI < Service
  string :token

  def receive_push
    http.ssl[:verify] = false
    http.headers['Content-Type'] = 'application/json'
    http_post hubci_url, {:commits => payload['commits']}.to_json
  end

  def hubci_url
    "https://node.ci/repository/#{repoOwner}/#{repoName}/onCommit/#{token}"
  end

  def repoName
    payload['repository']['name']
  end

  def repoOwner
    payload['repository']['owner']['name']
  end

  def token
    data['token'].to_s.strip
  end
end

