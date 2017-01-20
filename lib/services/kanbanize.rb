class Service::Kanbanize < Service
  string :kanbanize_domain_name
  string :kanbanize_api_key
  string :restrict_to_branch
  boolean :restrict_to_last_commit
  boolean :track_project_issues_in_kanbanize
  string :project_issues_board_id

  # Skip the api key from the debug logs.
  white_list :kanbanize_domain_name, :restrict_to_branch, :restrict_to_last_comment, :track_project_issues_in_kanbanize, :project_issues_board_id

  default_events :push, :issues, :issue_comment

  url "https://kanbanize.com/"
  logo_url "https://kanbanize.com/application/resources/images/logo.png"

  maintained_by :github => 'DanielDraganov'
  supported_by  :email => 'office@kanbanize.com'

  def receive_event
    # Make sure that the api key is provided.
    raise_config_error "Missing 'kanbanize_api_key'" if data['kanbanize_api_key'].to_s == ''
	
    domain_name = data['kanbanize_domain_name']
    api_key = data['kanbanize_api_key']
    branch_restriction = data['restrict_to_branch'].to_s
    commit_restriction = config_boolean_true?('restrict_to_last_commit')
    issues_tracking = config_boolean_true?('track_project_issues_in_kanbanize')
    issues_board_id = data['project_issues_board_id'].to_s
	
    # check the branch restriction is poplulated and branch is not included
    if event.to_s == 'push'
    	branch = payload['ref'].split('/').last
    	if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
	    return
    	end
    end

    http_post "http://#{domain_name}/index.php/api/kanbanize/git_hub_event",
      generate_json(payload),
      'apikey' => api_key,
      'branch-filter' => branch_restriction,
      'last-commit' => commit_restriction,
      'track-issues' => issues_tracking,
      'board-id' => issues_board_id,
      'Content-Type' => 'application/json'
  end
end
