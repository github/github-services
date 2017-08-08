class Service::IceScrum < Service
  string   :base_url, :access_token, :project_key, :username
  password :password
  def receive_push
	# Cloud only support access token
	if data['base_url'].to_s.empty?
		raise_config_error "Access token mandatory for cloud" if data['access_token'].to_s.empty?
	end

	 # Support old authentification for R6
	if data['access_token'].to_s.empty? 
		raise_config_error "Invalid username" if data['username'].to_s.empty?
		raise_config_error "Invalid password" if data['password'].to_s.empty?
	end
	
	# project key always mandatory
	raise_config_error "Invalid project key" if data['project_key'].to_s.empty?	
	project_key = data['project_key'].to_s.upcase.gsub(/\s+/, "")	
	  
	# setup base url
	if data['base_url'].present?
    		if data['access_token'].to_s.empty?
			url = "#{data['base_url']}/ws/p/#{project_key}/commit"
		else
			url = "#{data['base_url']}/ws/project/#{project_key}/commit/github"
		end
		#we are not sure if https or not or even valid https
		http.ssl[:verify] = false
        else
		url = "https://cloud.icescrum.com/ws/project/#{project_key}/commit/github"
		#we do pay a lot to get a green light on the browser address bar :D
		http.ssl[:verify] = true
        end

	# do old basic authentication
	if data['access_token'].to_s.empty?
		username = data['username'].to_s.gsub(/\s+/, "")
		password = data['password'].to_s.gsub(/\s+/, "")
		http.basic_auth username, password
	else
		http.headers['Content-Type'] = 'application/json'
		http.headers['x-icescrum-token'] = data['access_token'].to_s.gsub(/\s+/, "")
	end
        
	http_post url, { :payload => generate_json(payload) }
  end

end
