class Service::CodePortingCSharp2Java < Service
  string   :project_name, :repo_key, :target_repo_key, :codeporting_username
  password :codeporting_password
  string   :github_access_token

  self.title = 'CodePorting-C#2Java'

  def receive_push
    return if Array(payload['commits']).empty?

    check_configuration_options(data)

    response = nil
    token = perform_login

    if token.blank?
      response = "Unable to login on codeporting.com at the moment :( "
      raise_config_error "#{response}"
    end

    response = process_on_codeporting(token)
    if response != "True"
      raise_config_error 'Porting performed with errors, porting will be performed again on next commit.'
    end

    response
  end

  def perform_login
    http.ssl[:verify] = false
    login_url = "https://apps.codeporting.com/csharp2java/v0/UserSignin"
    resp = http.post login_url do |req|
      req.body = {:LoginName => data['codeporting_username'], :Password => data['codeporting_password']}
    end

    doc = REXML::Document.new(resp.body)
    retValue = nil
    doc.each_element('//return') do |item|
      retValue = item.attributes['success']
    end

    if retValue == "True"
      token = nil
      doc.each_element('//Token') do |item|
        token = item.text
      end
      token
    end
  end

  def process_on_codeporting(token)
    process_url = "https://apps.codeporting.com/csharp2java/v0/githubpluginsupport"
    resp = http.post process_url do |req|
      req.body = {:token => token, :ProjectName => data['project_name'],
        :RepoKey => data['repo_key'], :TarRepoKey => data['target_repo_key'],
        :Username => data['codeporting_username'], :Password => data['codeporting_password'],
        :GithubAccessToken => data['github_access_token']}
    end

    doc = REXML::Document.new(resp.body)
    retValue = nil
    doc.each_element('//return') do |item|
      retValue = item.attributes['success']
    end
    retValue
  end

  private

  def check_configuration_options(data)
    raise_config_error 'Project name must be set' if data['project_name'].blank?
    raise_config_error 'Repository is required' if data['repo_key'].blank?
    raise_config_error 'Target repository is required' if data['target_repo_key'].blank?
    raise_config_error 'Codeporting username must be provided' if data['codeporting_username'].blank?
    raise_config_error 'Codeporting password must be provided' if data['codeporting_password'].blank?
    raise_config_error 'GitHub Access Token must be provided for commiting changes back to GitHub' if data['github_access_token'].blank?
  end
end
