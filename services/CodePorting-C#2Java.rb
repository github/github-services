class Service::CodePorting-C#2Java < Service
  string   :project_name, :repo_key, :target_repo_key, :username, :password
  boolean  :active

  def receive_push
    check_configuration_options(data)
  end

  private

  def check_configuration_options(data)
    raise_config_error 'Project name must be set' if data['project_name'].blank?
    raise_config_error 'Repository is required' if data['repo_key'].blank?
    raise_config_error 'Target repository is required' if data['target_repo_key'].blank?
    raise_config_error 'Codeporting username must be provided' if data['username'].blank?
    raise_config_error 'Codeporting password must be provided' if data['password'].blank?
  end


end