class Service::NodeCI < Service
  string :token

  # backwards compatible change until we can migrate configured hooks on
  # github.com
  hook_name 'hubci'

  def receive_push
    http.ssl[:verify] = false
    http.headers['Content-Type'] = 'application/json'
    http_post hubci_url, generate_json(:commits => payload['commits'])
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

