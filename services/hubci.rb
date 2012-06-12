class Service::HubCI < Service
  string :token

  def receive_push
    http.ssl[:verify] = false
    payload['commits'].each do |commit|
        http_post hubci_url, commit.to_json
    end
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

