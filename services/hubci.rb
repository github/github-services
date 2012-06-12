class Service::HubCI < Service
  string :token

  def receive_push
    http.ssl[:verify] = false
    http_post hubci_url, :commits=>payload['commits'].to_json
  end

  def hubci_url
    "http://hub.ci/repository/"+repoOwner+"/"+repoName+"/onCommit/"+token
  end

  def repoName
    payload['repository']['name'].strip
  end

  def repoOwner
    payload['repository']['owner']['name'].strip
  end

  def token
    data['token'].strip
  end
end

