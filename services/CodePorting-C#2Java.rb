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
	uri = URI.parse("https://apps.codeporting.com")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	path = '/csharp2java/v0/UserSignin'
	data = "LoginName=#{username}&Password=#{password}"
	headers = {
		'Content-Type' => 'application/x-www-form-urlencoded'
	}
	resp, data = http.post(path, data, headers)
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
	uri = URI.parse("https://apps.codeporting.com")
	http_porting = Net::HTTP.new(uri.host, uri.port)
	http_porting.use_ssl = true
	http_porting.verify_mode = OpenSSL::SSL::VERIFY_NONE
	path_porting = '/csharp2java/v0/githubpluginsupport'
	data_porting = "token=#{token}&ProjectName=#{project_name}&RepoKey=#{repo_key}&TarRepoKey=#{target_repo_key}&Username=#{username}&Password=#{password}&GithubUserId=#{userid}"
	
	headers_porting = {
		'Content-Type' => 'application/x-www-form-urlencoded'
	}
	resp, data = http_porting.post(path_porting, data_porting, headers_porting)

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
