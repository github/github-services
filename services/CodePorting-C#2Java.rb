class Service::CodePortingCSharp2Java < Service
  string   :project_name, :repo_key, :target_repo_key, :username, :password
  boolean  :active
  string   :userid
  
  self.title = 'CodePorting-C#2Java'

  def receive_push
    response = ""
	
	return if Array(payload['commits']).size == 0
	
    check_configuration_options(data)
	
	perform_login
	
	if (token == "")
		response = "Unable to login on codeporting.com at the moment :( "
		raise_config_error "#{response}"
	else
		response = process_on_codeporting
		if (response == "True")
			#process successful
		else
			raise_config_error 'Porting performed with errors, porting will be performed again on next commit.'
		end
	end
	
	response
  end
  
  def perform_login
	http.ssl[:verify] = false
    postdata = "LoginName=#{username}&Password=#{password}"
	headers = {
		'Content-Type' => 'application/x-www-form-urlencoded'
	}
    resp, data = http_post "https://apps.codeporting.com/csharp2java/v0/UserSignin", postdata, headers

	doc = REXML::Document.new(data)
	retValue = ""
	doc.each_element('//return') { |item| 
		retValue = item.attributes['success']
	}

	if (retValue == "True")
		doc.each_element('//Token') { |item| 
			token = item.text
		}
	else
		token = ""
	end
  end
  
  def process_on_codeporting
	http.ssl[:verify] = false
    postdata = "token=#{token}&ProjectName=#{project_name}&RepoKey=#{repo_key}&TarRepoKey=#{target_repo_key}&Username=#{username}&Password=#{password}&GithubUserId=#{userid}"
	headers = {
		'Content-Type' => 'application/x-www-form-urlencoded'
	}
    resp, data = http_post "https://apps.codeporting.com/csharp2java/v0/githubpluginsupport", postdata, headers

	doc = REXML::Document.new(data)
	retValue = ""
	doc.each_element('//return') { |item| 
		retValue = item.attributes['success']
	}
	retValue
  end
  
  private

  string :token
  
  def check_configuration_options(data)
    raise_config_error 'Project name must be set' if data['project_name'].blank?
    raise_config_error 'Repository is required' if data['repo_key'].blank?
    raise_config_error 'Target repository is required' if data['target_repo_key'].blank?
    raise_config_error 'Codeporting username must be provided' if data['username'].blank?
    raise_config_error 'Codeporting password must be provided' if data['password'].blank?
  end


end
