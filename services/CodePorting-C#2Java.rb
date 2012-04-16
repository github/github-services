class Service::CodePorting-C#2Java < Service
  string   :project_name, :repo_key, :target_repo_key, :username, :password
  boolean  :active
  string   :userid
  
  repoPath = "https://github.com/#{userid}/#{repo_key}/zipball/master"
  download_file = open("RepositoryCode.zip", "wb")
  
  def redirect_url (response)
	if response.nil?
		return
	end
	if response == ''?
		return
	end
    if response['location'].nil?
      response.body.match(/<a href=\"([^>]+)\">/i)[1]
    else
      response['location']
    end
  end
  
  def get_repo_code
    download_file = open("RepoCode.zip", "wb")
	begin
		resp = ''
		begin
			url = URI.parse(path)
			request = Net::HTTP.new(url.host, url.port)
			request.use_ssl = true
			request.verify_mode = OpenSSL::SSL::VERIFY_NONE
			resp = request.request_get(url.path)
		
			if resp.kind_of?(Net::HTTPRedirection)
				path = redirect_url(resp)
			end
		end while resp.kind_of?(Net::HTTPRedirection)
	
		#resp.read_body { |segment| download_file.write(segment) }
		download_file.write(resp.body)
	end
	download_file.close
  end
  
  def receive_push
	return if Array(payload['commits']).size == 0
	
    check_configuration_options(data)
	
	perform_login
	
	if (token == "")
		create_new_project
	else
		get_repo_code
	end
  end

  def create_new_project
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
	
	retValue = ""
	doc.each_element('//return') { |item| 
	retValue = item.attributes['success']
	}

	if (retValue == "True")
		doc.each_element('//Token') { |item| 
		token = item
		}
	else
		token = ""
	end
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

# https://apps.codeporting.com
# /csharp2java/v0/UserSignin


end