class Service::Freckle < Service::HttpPost
  string :subdomain, :project
  password :token
  white_list :subdomain, :project

  default_events :push

  url "https://letsfreckle.com"

  maintained_by :github => 'LockeCole117', :twitter => '@LockeCole117'

  supported_by :web => 'https://letsfreckle.com',
  	:email => 'support@letsfreckle.com',
  	:twitter => '@letsfreckle'

  def receive_event
    subdomain = required_config_value('subdomain').strip
    token = required_config_value('token').strip
    project = required_config_value('project').strip

    http.headers['X-FreckleToken'] 	 = token
    http.headers['X-FreckleProject'] = project
    url = "https://#{data['subdomain']}.letsfreckle.com/api/github/commits"
    deliver url
  end
end
