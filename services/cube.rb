class Service::Cube < Service
  string :domain, :project, :token
  white_list :domain, :project

  def receive_push
    http_post "http://cube.bitrzr.com/integration/events/github/create",
      'payload' => JSON.generate(payload),
      'project_name' => data['project'],
      'project_token' => data['token'],
      'domain' => data['domain']
  end
end
