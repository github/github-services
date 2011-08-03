class Service::Kanbanery < Service

  def receive_push
    project_id = data['project_id']
    token = data['project_token']

    http_post "http://kanbanery.com/api/v1/projects/#{project_id}/git_commits",
      payload.to_json,
      'X-Kanbanery-ProjectGitHubToken' => token,
      'Content-Type' => 'application/json'
    
  end
  
end
