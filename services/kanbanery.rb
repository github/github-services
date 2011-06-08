secrets = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'secrets.yml'))
site = "http://smackaho.st:3000"
@uri = URI.parse(site)

service :kanbanery do |data, payload|
  project_id = data['project_id']
  api_token = data['api_token']
  commits   = [ ]
  repository = payload['repository']['name']


  payload['commits'].each do |commit|
    commit['shortened_url'] = shorten_url(commit['url'])
  end

  @uri.path = "/api/v1/projects/#{project_id}/git_commits"
  http = Net::HTTP.new(@uri.host, @uri.port)
  request = Net::HTTP::Post.new(@uri.request_uri, {'X-Kanbanery-ApiToken' => api_token})
  request.body = payload.to_json
  request.content_type = 'application/json'
  response = http.request(request)
  
  
end