secrets = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'secrets.yml'))
site = "http://smackaho.st:3000"
@uri = URI.parse(site)

service :kanbanery do |data, payload|
  project_id = data['project_id']
  api_token = data['api_token']
  repository = payload['repository']['name']
  owner = payload['repository']['owner']['name']

  payload['commits'].each do |commit|
    commit['shortened_url'] = shorten_url(commit['url'])
  end

#
#  for master_branch
#
  uri = URI.parse("https://github.com/api/v2/json/repos/show/#{owner}/#{repository}")
  http = Net::HTTP.new(uri.host)
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  if response.is_a?(Net::HTTPOK)
    res = JSON.parse(response.body)
    payload['master_branch'] = res['repository']['master_branch'] || "master"
  end
  payload['master_branch'] ||= "master"

#
#  for list of branches
#
  uri = URI.parse("https://github.com/api/v2/json/repos/show/#{owner}/#{repository}/branches")
  http = Net::HTTP.new(uri.host)
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  if response.is_a?(Net::HTTPOK)
    res = JSON.parse(response.body)
    payload['branches'] = res['branches'].keys
  end

  @uri.path = "/api/v1/projects/#{project_id}/git_commits"
  http = Net::HTTP.new(@uri.host, @uri.port)
  request = Net::HTTP::Post.new(@uri.request_uri, {'X-Kanbanery-ApiToken' => api_token})
  request.body = payload.to_json
  request.content_type = 'application/json'
  response = http.request(request)
  
end