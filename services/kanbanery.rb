site = "http://smackaho.st:3000"
@uri = URI.parse(site)

service :kanbanery do |data, payload|
  project_id = data['project_id']
  token = data['project_token']

  @uri.path = "/api/v1/projects/#{project_id}/git_commits"
  http = Net::HTTP.new(@uri.host, @uri.port)
  request = Net::HTTP::Post.new(@uri.request_uri, {'X-Kanbanery-ProjectGitHubToken' => token})
  request.body = payload.to_json
  request.content_type = 'application/json'
  response = http.request(request)
  
end