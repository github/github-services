class Service::Devaria < Service::HttpPost
	string :project_name, :username, :user_class_id
	
	white_list :project_name, :username, :user_class_id
	
	default_events :push, :member, :public, :issues, :gollum
	
	url "http://devaria.com"
	maintained_by :github => 'jonbonazza'
	
	supported_by :web => 'http://www.createtank.com/contactUs/'
	@@url_base = "http://www.devaria.com/hooks"
	def receive_push
		username = required_config_value('username')
		project = required_config_value('project_name')
		url = @@url_base + "/push"
		body = {'owner'=>username, 'project_name'=>project, 'payload'=>payload}
		body = generate_json(body)
		make_request(url, body)
		print body
	end
	
	def make_request(url, body)
		wrap_http_errors do
			url = set_url(url)
			http.headers['content-type'] = 'application/json'
			http_post url, body
		end
	end
	
	def receive_member
		username = required_config_value('username')
		project = required_config_value('project_name')
		
		url = @@url_base + "/member"
		body = {'owner'=>username, 'project_name'=>project, 'payload'=>payload}
		body = generate_json(body)
		make_request(url, body)
	end
	
	def receive_public
		username = required_config_value('username')
		project = required_config_value('project_name')
		
		url = @@url_base + "/public"
		body = {'owner'=>username, 'project_name'=>project, 'payload'=>payload}
		body = generate_json(body)
		make_request(url, body)
	end
	
	def receive_issues
		username = required_config_value('username')
		project = required_config_value('project_name')
		
		url = @@url_base + "/issues"
		body = {'owner'=>username, 'project_name'=>project, 'payload'=>payload}
		body = generate_json(body)
		make_request(url, body)
	end
	
	def receive_gollum
		username = required_config_value('username')
		project = required_config_value('project_name')
		
		url = @@url_base + "/gollum"
		body = {'owner'=>username, 'project_name'=>project, 'payload'=>payload}
		body = generate_json(body)
		make_request(url, body)
	end
end
