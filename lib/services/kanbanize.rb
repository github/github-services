class Service::Kanbanize < Service
  string :kanbanize_domain_name
  string :kanbanize_api_key
  string :restrict_to_branch
  boolean :restrict_to_last_commit

  # Skip the api key from the debug logs.
  white_list :kanbanize_domain_name, :restrict_to_branch, :restrict_to_last_comment

  url "https://kanbanize.com/"
  logo_url "https://kanbanize.com/application/resources/images/logo.png"

  maintained_by :github => 'DanielDraganov'
  supported_by  :email => 'office@kanbanize.com'

  def receive_push
    # Make sure that the api key is provided.
    raise_config_error "Missing 'kanbanize_api_key'" if data['kanbanize_api_key'].to_s == ''
    
    domain_name = data['kanbanize_domain_name']
    api_key = data['kanbanize_api_key']
    branch_restriction = data['restrict_to_branch'].to_s
    commit_restriction = config_boolean_true?('restrict_to_last_commit')
    
    # check the branch restriction is poplulated and branch is not included
    branch = payload['ref'].split('/').last
    if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
      return
    end

     http_post "http://#{domain_name}/index.php/api/kanbanize/git_hub_event",
      generate_json(payload),
      'apikey' => api_key,
      'branch-filter' => branch_restriction,
      'last-commit' => commit_restriction,
      'Content-Type' => 'application/json'
  end
end
