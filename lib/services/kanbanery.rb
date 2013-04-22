class Service::Kanbanery < Service
  string :project_id, :project_token
  white_list :project_id

  def receive_push
    project_id = data['project_id']
    token = data['project_token']

    http_post "https://kanbanery.com/api/v1/projects/#{project_id}/git_commits",
      generate_json(payload),
      'X-Kanbanery-ProjectGitHubToken' => token,
      'Content-Type' => 'application/json'
  end
end

